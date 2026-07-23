# cosmos_client

화장품 성분 기반 추천 앱 — Flutter 클라이언트 (프론트)

백엔드는 별도 저장소 [cosmos_server](https://github.com/cosmos-incicrew/cosmos_server)
(FastAPI)이며, 앱은 Supabase Auth로 로그인해 JWT를 받아 서버 API를 호출한다.
설계·규칙은 [docs/architecture.md](docs/architecture.md)·[docs/conventions.md](docs/conventions.md),
API 계약 상세는 **[docs/api-contract.md](docs/api-contract.md)** 참고.

Vercel 개발 배포 담당자는 [Vercel 배포 가이드](docs/vercel-deployment.md)를
위에서부터 따라가면 된다. 현재 개발 주소는 <https://cosmos-incicrew.vercel.app>이다.

> **환경 값(`--dart-define`)이 없으면**: 로그인은 게스트·네이버(목업)만 되고,
> 검색·추천·보고서·비교는 빈 화면이다 (버그 아님 — 에러/빈 결과를 구분해 표시).
> 값을 넣으면 그대로 실서버를 호출한다. 아래 [실행 방법](#실행-방법) 참고.

## 기술 스택

| 구분 | 사용 기술 |
|------|-----------|
| 프레임워크 | Flutter (Dart) |
| 디자인 | Material 3 + cosmos 커스텀 테마 (픽셀 컨셉: PixelBox·갈무리 서체) |
| 상태관리 | Riverpod (`flutter_riverpod`) |
| 라우팅 | `go_router` (StatefulShellRoute — 고정 헤더/푸터) |
| 네트워킹 | `supabase_flutter`(인증) + `dio`(API, JWT 자동 첨부) |
| 이미지 로딩 | `cached_network_image` |
| 로컬 저장소 | Hive + `flutter_secure_storage` |
| 로그인 | 카카오(웹 OAuth 딥링크) · 구글(네이티브) · 게스트 · 네이버(목업) |

## 화면 구조 — 헤더·푸터 고정

모든 메인 화면은 쉘(`AppShell`) 안에 있다. **헤더(햄버거 서랍 · COSMOS 로고 ·
마이)와 푸터(화장대/홈/마이 탭)는 쉘이 고정**으로 갖고, 화면들은 자기 AppBar
없이 body 상단 `ScreenTitle`(뒤로가기+제목)만 갖는다.
쉘 밖은 로그인 전 진입 흐름(스플래시·온보딩)뿐이다.

**반응형**: 폰 시안 기준 레이아웃이라 콘텐츠를 최대 480px 중앙 정렬로 제한한다
(`ContentWidth`, 쉘이 일괄 적용). 넓은 표(비교 표 등)는 자기 영역 안에서만
가로 스크롤한다.

```
쉘 안 (헤더·푸터 고정)
├─ 화장대 탭   /shelf → add(검색·담기) → product(제품 상세) → ingredient(성분 상세)
├─ 홈 탭       /home → /bsti(검사) · /recommendation(추천) · /report(보고서) · /compare(비교)
└─ 마이 탭     /profile → edit(프로필 수정)

쉘 밖 (로그인 전)
└─ /splash → /onboarding → 로그인 시트 → profile → concerns → done
```

## API 구성 (프론트 ↔ cosmos_server)

**원칙: 화면은 저장소(repository)만 본다.** 저장소가 실제 엔드포인트를
호출하고, 서버 필드명(snake_case)과 프론트 모델의 차이를 저장소에서 흡수한다.
전 호출에 Supabase JWT 가 자동 첨부된다 (`dio_client.dart` 인터셉터).

### 연동 완료 (백엔드 코드와 대조 검증됨)

| 엔드포인트 | 프론트 메서드 | 쓰는 화면 |
|---|---|---|
| `GET /api/v1/products/search` | `ProductRepository.search` | 검색·비교 |
| `GET /api/v1/products/{id}/ingredients` | `.getIngredientIds` | 제품 상세·보고서 |
| `POST /api/v1/products/compare` | `.compare` | 비교 |
| `GET /api/v1/ingredients/search` | `IngredientRepository.search` | 검색 |
| `GET /api/v1/ingredients/{id}/detail` | `.getDetail` | 성분 해설 (①) |
| `POST /api/v1/ingredients/product-summary` | `.getProductSummary` | 제품 상세 요약 (②) |
| `POST /api/v1/ingredients/comparison-summary` | `.getComparisonSummary` | 비교 해설 (③) |
| `GET·POST /api/v1/users/me/profile`, `DELETE /users/me` | `ProfileRepository` | 온보딩·프로필·탈퇴 |

주의해서 매핑한 것 (자세한 건 [docs/api-contract.md](docs/api-contract.md)):

- 서버는 `name_kr`/`name_en`, 프론트 모델은 `nameKor`/`nameEng` — 저장소가 명시 매핑
- 제품 검색 응답의 id 필드는 `id` (`product_id` 아님)
- 검색 응답에 성분 id 없음 — 2단계 설계 (`/products/{id}/ingredients` 별도)
- ①②③의 `status: "확인 불가"` 는 에러가 아님 → "정보 없음" 안내로 표시
- `safety` 3형태: `[공식 규제]`(경고 강조) / 일반 / `안전성 확인 불가`(= 모른다, 안전 아님)
- ②③ `summary` 의 "주의: " 줄은 분리해 강조 표시
- ③ 요청은 compare 응답을 그대로 전달 (여분 필드는 서버가 무시)

### 서버에 있지만 미연동

| 엔드포인트 | 비고 |
|---|---|
| `POST /api/v1/recommendations` | RAG 추천 — 현재 추천 화면은 프론트 계산. 개편 시 전환 |
| `POST /api/v1/bsti/submit` | 501 스텁 — BSTI 는 프론트 완결이라 불필요 (아래) |

### BSTI 는 프론트 완결 (팀 결정)

검사 문항 20 · 유형 16 · 성분 사전 34 전부 프론트가 들고 채점한다.
서버 DB에 BSTI 매핑이 없으므로, 보고서 적합도는 성분 **이름 정확 일치**로
프론트가 잇는다 (`bsti_name_matcher.dart`). 매칭 안 된 성분은 점수를
지어내지 않고 "판단 정보 부족"으로 표시된다. 결과 저장은 프로필(서버)을 탄다.

## 폴더 구조

```
lib/
├─ app/
│  ├─ router/              # go_router + AppShell (고정 헤더·푸터, ContentWidth)
│  └─ theme/               # 색·타이포·에셋 경로
├─ core/
│  ├─ config/              # Env (--dart-define)
│  ├─ network/             # dio (JWT 인터셉터) + Supabase 클라이언트
│  ├─ storage/             # Hive + secure storage
│  └─ widgets/             # PixelBox·PixelButton·ScreenTitle·AppDrawer 등
└─ features/               # 기능별: data/(모델·저장소·프로바이더) + presentation/
   ├─ auth/                # 로그인 (카카오·구글 실연동, 네이버 목업, 게스트)
   ├─ onboarding/          # 프로필 등록·피부고민·완료 (서버 프로필 연동)
   ├─ home/                # 홈 메뉴
   ├─ bsti/                # 피부 MBTI ★ 평탄 구조 (데이터·엔진·화면 한곳)
   ├─ my_shelf/            # 화장대·검색·제품/성분 상세 (①② 해설 연동)
   ├─ compare/             # 다중 제품 비교 (비교표 + ③ 해설)
   ├─ product/ ingredient/ # 모델 + 저장소 (API 연동 지점)
   ├─ recommendation/      # 맞춤 추천 (유형·고민·기피 반영, 프론트 계산)
   ├─ report/              # 화장대 보고서 (적합도 + 부족 성분)
   └─ profile/             # 마이페이지 (로그아웃·탈퇴)
```

## 실행 방법

```bash
flutter pub get

# 환경 값 없이 (게스트 + 빈 화면 데모)
flutter run -d chrome

# 실서버 연동 (값은 팀 공유 — README of cosmos_server 참고)
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhb... \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com
```

- `API_BASE_URL` 비어 있으면 저장소는 호출 없이 빈 결과 (에러 화면 아님)
- Supabase 값 없으면 카카오·구글 버튼은 "준비 중" 안내
- 카카오 딥링크(`cosmos://login-callback`)는 AndroidManifest 와 일치해야 함

**로그인 없이 API 테스트 (개발용 토큰):**

서버의 모든 `/api/v1/*` 는 JWT 필수라, OAuth 설정 전에는 로그인할 방법이
없어 401 이 뜬다. 백엔드 레포에서 개발용 토큰을 발급해 꽂으면 우회된다:

```bash
# cosmos_server 폴더에서 (요구사항·주의는 그쪽 문서 참고)
uv run python scripts/dev_token.py     # → eyJ... 출력

# 프론트 실행 시 토큰을 넘긴다 (릴리즈 빌드에선 무시됨)
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=DEV_JWT=eyJ...
```

토큰은 약 1시간 유효 — 401 이 다시 뜨면 새로 발급한다.
실제 로그인 세션이 생기면 세션 토큰이 우선한다.

앱 아이콘: `assets/icons/app/app_icon.png`(1024×1024) 넣고
`dart run flutter_launcher_icons`.

## 테스트

```bash
flutter test        # 전체 (159개)
```

| 위치 | 내용 |
|---|---|
| `test/smoke_screens_test.dart` | 12개 화면을 실제 렌더링 — 예외·오버플로우 검증 |
| `test/features/bsti/` | BSTI 데이터 정합성·채점·이름 매칭 |
| `test/features/product/` `ingredient/` | **명세서 예시 JSON 원문**으로 파싱 검증 |
| `test/features/report/` `recommendation/` | 적합도·추천 규칙 |
| `test/features/auth/` `onboarding/` | 로그인·프로필 (팀원 작성 포함) |
| `test/support/fake_repositories.dart` | 가짜 저장소 — `ProviderContainer(overrides: fakeRepos)` |

샘플 데이터는 `test/` 안에만 둔다. `lib/` 에 목데이터 없음
(예외: 네이버 로그인 목업 — 의도된 것).

## 남은 작업

`grep -rn "TODO(BE)" lib/` 로 백엔드 요청 목록 확인.

1. 제품 상세의 **전체 성분 이름 목록** — 엔드포인트 없음. 지금은 대표성분 3개만
   행으로, 나머지는 "외 N개 분석됨" (성분 일괄 조회 생기면 풀림)
2. 성분→제품 역조회 — 성분 상세 "포함 제품"·보고서 추천 제품이 빈 상태
3. 추천 화면의 `POST /recommendations` 전환 (현재 프론트 계산)
4. 마이페이지 찜한 제품·최근 본 제품·설정 (스텁)
