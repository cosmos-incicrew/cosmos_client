# API 연동 계약 (프론트 ↔ cosmos_server)

백엔드 레포([cosmos_server](https://github.com/cosmos-incicrew/cosmos_server))를
직접 확인해 작성했다 (2026-07-22 기준). 화면은 저장소(repository)만 보고,
저장소가 아래 엔드포인트를 호출한다.

개발·배포 서버 주소 설정과 CORS 확인 순서는
[백엔드 연결 가이드](backend-connection.md)를 참고한다.

## 인증 구조 — 로그인 엔드포인트는 없다

서버에는 로그인 API가 **없다.** 서버는 **Supabase JWT를 검증만** 한다
(`app/core/auth.py` — Bearer 토큰, HS256, audience `authenticated`).

즉 로그인 흐름은:

1. 앱이 **Supabase Auth OAuth** 로 직접 로그인 (카카오·구글 — 공유 Supabase
   프로젝트에 제공자 설정됨)
2. 받은 액세스 토큰을 모든 `/api/v1/*` 호출에 `Authorization: Bearer` 로 첨부
   (`lib/core/network/dio_client.dart` 인터셉터가 자동 처리)

검증 방식은 **ES256/JWKS** — Supabase 가 개인키로 서명하고 서버는 공개키로
검증만 한다. 프론트는 방식과 무관하게 토큰만 실어 보내면 된다.

**개발용 토큰**: OAuth 설정 전에는 백엔드의 `scripts/dev_token.py` 로 발급한
토큰을 `--dart-define=DEV_JWT=...` 로 꽂아 테스트한다 (릴리즈 빌드 무시,
실세션 우선, 약 1시간 만료). Swagger 테스트도 같은 토큰을 쓴다
(Authorize 에 `Bearer` 빼고 토큰만).

앱 실행에 필요한 값 (`--dart-define`):

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhb... \
  --dart-define=API_BASE_URL=http://localhost:8000   # cosmos_server 주소
```

값이 비어 있으면: Supabase 로그인 버튼은 "준비 중" 안내, 저장소는 빈 결과
(에러가 아니라 빈 화면 — 의도된 동작).

## 구현된 엔드포인트 (프론트 연동 완료)

| 엔드포인트 | 프론트 메서드 | 비고 |
|---|---|---|
| `GET /api/v1/products/search?q=&limit=` | `ProductRepository.search` | 제품명 검색 |
| `GET /api/v1/products/{id}/ingredients` | `ProductRepository.getIngredientIds` | 확정 성분 id (배합 순서) |
| `POST /api/v1/products/compare` | `ProductRepository.compare` | 다중 제품 비교 (2~4개) |
| `GET /api/v1/ingredients/search?q=&limit=` | `IngredientRepository.search` | 성분 이명 검색 |
| `GET /api/v1/ingredients/{id}/detail` | `IngredientRepository.getDetail` | ① 개별 성분 해설 |
| `POST /api/v1/ingredients/product-summary` | `IngredientRepository.getProductSummary` | ② 대표성분 Top-3 + 요약 |
| `POST /api/v1/ingredients/comparison-summary` | `IngredientRepository.getComparisonSummary` | ③ 비교 해설 (compare 응답을 그대로 전달) |

**성분 해설 API(①②③) 공통 규칙** (노션 "성분 해설 API 명세" 요약):

- `status: "확인 불가"` 는 **에러가 아니다** — 정보가 아직 없다는 뜻.
  정상 화면에 "아직 정보가 없습니다"를 띄운다. 404 만 잘못된 id.
- `safety` 는 세 형태: `[공식 규제]` 시작(경고 강조) / 일반 참고(보통) /
  `안전성 확인 불가`(**"안전하다"가 아니라 "모른다"** — 안전 표시 금지).
  분류 헬퍼: `classifySafety()`.
- ②③ `summary` 의 "주의: " 줄은 `splitCaution()` 으로 분리해 강조한다.
- `source_verified: false` = 검증 안 된 출처를 서버가 제거함. **본문은 유효** —
  출처만 표시하지 않는다.
- ③ 비교 해설은 성분 **구성 차이**만 말한다. 제품 우열·추천은 오지 않는다
  (배합 비율 비공개 — 판단 근거 없음).

**응답 필드 주의:**

- 제품 검색의 id 필드는 **`id`** (프론트 모델 fromJson의 `product_id` 아님 —
  저장소가 명시 매핑)
- 성분은 **`name_kr` / `name_en`** (프론트의 `name_kor` / `name_eng` 아님 —
  저장소가 명시 매핑. fromJson 그대로 쓰면 조용히 null 됨)
- 제품 **검색 응답에 `ingredient_ids` 없음** — 2단계 설계.
  상세에서 `/products/{id}/ingredients` 로 따로 받는다.
- `/products/{id}/ingredients` 에러: 404 `PRODUCT_NOT_FOUND`,
  422 `PRODUCT_NOT_ANALYZABLE`

## 서버에 있지만 아직 프론트 미연동

| 엔드포인트 | 내용 |
|---|---|
| `POST /api/v1/recommendations` | RAG 추천 (성분 중심 응답 — 추천 화면 개편 필요) |
| `POST/GET /api/v1/users/me/profile` 외 | 프로필 (팀원이 연동 완료 — `ProfileRepository`) |

**저장소는 연동됐지만 화면이 아직 안 쓰는 것**: compare·①②③은
저장소 메서드까지 준비됐다. 비교 화면은 신규 화면이라 디자인 확정 후 작업,
제품 상세의 ② 전환은 별도 작업.

## BSTI 는 프론트 완결 (팀 결정)

서버 DB에 `bsti_ingredient_id` 매핑은 **없고, 만들지 않는다.**
프론트가 BSTI 사전(`kBstiIngredients` 34개)의 한글명·INCI 를 서버 성분의
`name_kr`/`name_en` 과 **정확 일치**로 대조해 직접 잇는다
(`lib/features/bsti/bsti_name_matcher.dart` +
`IngredientRepository.bstiIdsByProducts`).

- 인덱스는 앱 실행당 한 번 구성 (성분당 검색 1~2회, 캐시)
- 이름 표기가 서버와 달라 안 잡힌 성분은 그냥 빠진다 — 보고서가
  "판단 정보 부족"으로 표시할 뿐 틀린 점수를 만들지 않는다
- 서버 성분 데이터의 표기가 BSTI 사전과 다르면 매칭률이 떨어지므로,
  **실데이터로 한 번 매칭률을 확인**해보고 필요하면 사전에 이명을 보강한다

## ⚠️ 백엔드에 요청하면 좋은 것 (없어도 앱은 돌지만 해당 기능이 빔)

`grep -rn "TODO(BE)" lib/` 로 코드 위치 확인.

1. **성분 일괄 조회 없음** — 제안: `GET /api/v1/ingredients?ids=101,102`
   (**응답 순서 = 요청 순서.** 제품 상세가 앞 3개를 대표성분으로 씀)
2. **성분→제품 역조회 없음** — 제안: `GET /api/v1/ingredients/{id}/products`
   (성분 상세의 "이 성분이 든 제품" + 보고서의 "이 제품을 추천해요")
3. **제품 전체 목록 없음** — 추천 화면이 임시로 쓰던 것. 실제로는
   `POST /api/v1/recommendations` 로 옮기는 게 맞으므로 우선순위 낮음.

## 에러 응답 공통 형식

```json
{ "error": { "code": "PRODUCT_NOT_FOUND", "message": "제품을 찾을 수 없습니다." } }
```

인증 실패: 401 `AUTH_MISSING_TOKEN` / `AUTH_INVALID_TOKEN`.

## 테스트에서 쓰는 가짜 저장소

`test/support/fake_repositories.dart` — 저장소 프로바이더를 override:

```dart
final container = ProviderContainer(overrides: fakeRepos);
```

**앱 코드(`lib/`)에는 샘플 데이터를 두지 않는다.**
(예외: 네이버 로그인은 실제 연동 계획이 없어 의도적으로 목업 —
`AuthRepository.signInWithNaver`)
