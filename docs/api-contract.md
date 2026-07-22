# API 연동 계약 (프론트 ↔ cosmos_server)

백엔드 레포([cosmos_server](https://github.com/cosmos-incicrew/cosmos_server))를
직접 확인해 작성했다 (2026-07-22 기준). 화면은 저장소(repository)만 보고,
저장소가 아래 엔드포인트를 호출한다.

## 인증 구조 — 로그인 엔드포인트는 없다

서버에는 로그인 API가 **없다.** 서버는 **Supabase JWT를 검증만** 한다
(`app/core/auth.py` — Bearer 토큰, HS256, audience `authenticated`).

즉 로그인 흐름은:

1. 앱이 **Supabase Auth OAuth** 로 직접 로그인 (카카오·구글 — 공유 Supabase
   프로젝트에 제공자 설정됨)
2. 받은 액세스 토큰을 모든 `/api/v1/*` 호출에 `Authorization: Bearer` 로 첨부
   (`lib/core/network/dio_client.dart` 인터셉터가 자동 처리)

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
| `GET /api/v1/ingredients/search?q=&limit=` | `IngredientRepository.search` | 성분 이명 검색 |

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
| `GET /api/v1/ingredients/{id}/detail` | 성분 LLM 해설 (status/name/body/safety) |
| `POST /api/v1/ingredients/product-summary` | `{ingredient_ids}` → 대표성분+요약. **제품 상세를 이쪽으로 개편하는 게 서버 설계와 맞음** |
| `POST /api/v1/products/compare` | 다중 제품 교차 비교 |
| `POST /api/v1/recommendations` | RAG 추천 (성분 중심 응답 — 추천 화면 개편 필요) |
| `POST /api/v1/bsti/submit` | **501 스텁** (담당: 금별 — 프론트가 자체 채점하므로 급하지 않음) |

## ⚠️ 백엔드에 요청 필요 (없으면 해당 기능이 빈 화면)

`grep -rn "TODO(BE)" lib/` 로 코드 위치 확인.

1. **`bsti_ingredient_id` 매핑이 DB에 없다.**
   `ingredients` 테이블(001_create_ingredients.sql)에 해당 컬럼/테이블 없음.
   **보고서 적합도 점수·부족 성분 추천이 전부 여기 걸려 있다.**
   앱이 아는 id 34개는 `lib/features/bsti/bsti_dataset.dart` 의 `kBstiIngredients`.
2. **성분 일괄 조회 없음** — 제안: `GET /api/v1/ingredients?ids=101,102`
   (**응답 순서 = 요청 순서.** 제품 상세가 앞 3개를 대표성분으로 씀)
3. **성분→제품 역조회 없음** — 제안: `GET /api/v1/ingredients/{id}/products`
   (성분 상세의 "이 성분이 든 제품")
4. **제품 전체 목록 없음** — 추천 화면이 임시로 쓰던 것. 실제로는
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
