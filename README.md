# cosmos_client

화장품 성분 기반 추천 앱의 Flutter 클라이언트입니다. 안드로이드와 웹으로 실행합니다.

백엔드는 별도 저장소 [cosmos_server](https://github.com/cosmos-incicrew/cosmos_server)(FastAPI)이며,
앱은 Supabase Auth로 로그인해 받은 JWT로 서버 API를 호출합니다.

<!-- 스크린샷: 홈 · BSTI 결과 · 제품 상세 · 비교표 · 화장대 보고서 (추후 추가) -->

## 주요 기능

화면 전반에 공통 규칙이 하나 있습니다. **근거가 없으면 점수나 설명을 지어내지 않고
"판단 정보 부족"이라고 말합니다.** 아래 기능들은 모두 이 규칙을 따릅니다.

### 화장대와 검색

제품명이나 성분명으로 검색해 화장대에 담습니다. 제품 상세에서는 담긴 제품의 성분
목록과 요약 해설을, 성분 상세에서는 개별 성분의 설명을 봅니다.
`/shelf → add(검색) → product → ingredient`로 이어지는 흐름이고, 검색과 해설은 모두
서버 API를 씁니다.

### 성분 해설

개별 성분의 설명과 주의사항을 보여줍니다. 서버가 `확인 불가`를 돌려주면 에러 화면 대신
"정보 없음"으로 안내합니다. 안전성 표기는 세 가지를 구분합니다 — 공식 규제(경고를
강조), 일반, 안전성 확인 불가. 마지막은 안전하다는 뜻이 아니라 판단할 자료가 없다는
뜻이라 그렇게 읽히도록 문구를 씁니다. 요약문의 "주의:" 줄은 따로 떼어 강조합니다.

### 제품 비교

여러 제품의 성분을 표로 비교하고 해설을 함께 보여줍니다. 비교표는 서버 응답을 그대로
쓰지만, **제품 궁합 점수는 앱이 계산합니다**(`compare/engine/compare_match.dart`).
기본 70점에서 시작해 같이 쓰면 좋은 성분 조합마다 가점, 공통 성분이 있으면 가점,
규제 성분이 두 제품에 겹치면 감점하고 5~100 사이로 자릅니다. 근거가 없는 항목은
빈 목록으로 두고 화면이 "없어요"를 표시합니다.

### BSTI 16타입

문항 20개로 피부 타입을 판정합니다. 문항·유형·성분 사전을 앱이 직접 들고 채점합니다.
서버 DB에 BSTI 매핑이 없어서 내린 팀 결정이고, 보고서의 적합도는 성분 이름 정확
일치로 잇습니다(`bsti_name_matcher.dart`). 매칭되지 않은 성분은 점수를 매기지 않습니다.
결과 저장은 서버 프로필을 사용합니다.

### 맞춤 추천

피부 타입, 피부 고민, 기피 성분을 반영해 카테고리별로 성분과 제품을 추천합니다.
화면 상단에 **무엇을 반영했는지 그대로 보여줍니다** — BSTI 검사를 하지 않았으면 타입을
언급하지 않고, 반영한 항목만 적습니다.

### 화장대 보고서

화장대에 담긴 제품이 내 유형에 얼마나 맞는지 0~100으로 평가하고, 부족한 성분을
알려줍니다. 권장 성분과 주의 성분이 하나도 겹치지 않으면 점수를 내지 않고 "판단 정보
부족"으로 표시합니다. 점수 구간은 잘 맞아요(80 이상), 무난해요(50 이상),
주의가 필요해요로 나눕니다.

## 요구 사항

- Flutter 3.27 이상 / Dart 3.6 이상
- Android Studio 또는 Chrome
- 개발용 Supabase 값 (팀 공유)

## 설치·실행

가장 빠른 경로는 배포된 개발 API에 붙는 것입니다. 서버를 로컬에 띄울 필요가 없습니다.

```bash
flutter pub get
cp dart_defines/dev.example.json dart_defines/dev.json
```

`dart_defines/dev.json`에 값을 채웁니다.

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_...",
  "GOOGLE_WEB_CLIENT_ID": "...apps.googleusercontent.com",
  "API_BASE_URL": "https://api.....nip.io"
}
```

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

`dev.json`은 `.gitignore`에 있어 커밋되지 않습니다. `SUPABASE_SERVICE_ROLE_KEY`나
Kakao Admin 키처럼 서버용 비밀값은 앱에 넣지 않습니다.

**값 없이 실행하면** 게스트·네이버(목업) 로그인만 되고 검색·추천·보고서·비교는 빈
화면입니다. 버그가 아니라 의도된 동작이고, 에러와 빈 결과를 구분해 표시합니다.

**로그인 없이 API를 확인할 때는** 서버 저장소에서 개발용 토큰을 발급해 넘깁니다.
약 1시간 유효하며 릴리즈 빌드에서는 무시됩니다.

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:8000 \
  --dart-define=DEV_JWT=eyJ...
```

## 설정

| 환경값 | 설명 |
|---|---|
| `SUPABASE_URL` | Supabase 프로젝트 URL. 비면 카카오·구글 버튼이 "준비 중"으로 안내합니다 |
| `SUPABASE_PUBLISHABLE_KEY` | 공개 클라이언트 키. 전환 기간에는 `SUPABASE_ANON_KEY`도 읽습니다 |
| `API_BASE_URL` | 백엔드 주소. 끝에 `/`를 붙이지 않습니다. 비면 저장소가 호출 없이 빈 결과를 돌려줍니다 |
| `GOOGLE_WEB_CLIENT_ID` | 구글 로그인용 **웹** 클라이언트 ID (안드로이드 ID가 아닙니다) |
| `DEV_JWT` | 개발용 토큰. 실제 세션이 있으면 그쪽이 우선합니다 |

카카오 로그인 딥링크는 `cosmos://login-callback`이고 AndroidManifest의 intent-filter와
글자까지 같아야 합니다. 다르면 브라우저에서 로그인은 끝나는데 앱으로 돌아오지 않습니다.

Flutter Web은 브라우저 CORS 제한을 받습니다. 서버가 허용하는 origin은
`https://cosmos-incicrew.vercel.app`과 `http://localhost:3000`입니다. 다른 주소에서
테스트하려면 백엔드 허용 목록에 정확한 origin을 추가해야 합니다.

## 서버 연동

화면은 저장소(repository)만 봅니다. 저장소가 실제 엔드포인트를 호출하고, 서버 필드명
(snake_case)과 앱 모델의 차이를 저장소에서 흡수합니다. 모든 호출에 Supabase JWT가
자동으로 붙습니다(`dio_client.dart` 인터셉터).

| 엔드포인트 | 앱 메서드 | 쓰는 화면 |
|---|---|---|
| `GET /api/v1/products/search` | `ProductRepository.search` | 검색·비교 |
| `GET /api/v1/products/{id}/ingredients` | `.getIngredientIds` | 제품 상세·보고서 |
| `POST /api/v1/products/compare` | `.compare` | 비교 |
| `GET /api/v1/ingredients/search` | `IngredientRepository.search` | 검색 |
| `GET /api/v1/ingredients/{id}/detail` | `.getDetail` | 성분 해설 |
| `POST /api/v1/ingredients/product-summary` | `.getProductSummary` | 제품 상세 요약 |
| `POST /api/v1/ingredients/comparison-summary` | `.getComparisonSummary` | 비교 해설 |
| `GET` `POST /api/v1/users/me/profile`, `DELETE /users/me` | `ProfileRepository` | 온보딩·프로필·탈퇴 |

## 프로젝트 구조

```
lib/
├─ app/
│  ├─ router/      go_router + AppShell (고정 헤더·푸터, ContentWidth)
│  └─ theme/       색·타이포·에셋 경로
├─ core/
│  ├─ config/      Env (--dart-define)
│  ├─ network/     dio(JWT 인터셉터) + Supabase 클라이언트
│  ├─ policy/      표시 정책
│  ├─ storage/     Hive + secure storage
│  └─ widgets/     PixelBox · PixelButton · ScreenTitle · AppDrawer
└─ features/       기능별로 data/(모델·저장소·프로바이더) + presentation/
   ├─ auth/            로그인 (카카오·구글 실연동, 네이버 목업, 게스트)
   ├─ onboarding/      프로필 등록·피부고민·완료
   ├─ home/            홈 메뉴
   ├─ bsti/            피부 MBTI — 데이터·엔진·화면을 한곳에 둔 평탄 구조
   ├─ my_shelf/        화장대·검색·제품/성분 상세
   ├─ compare/         다중 제품 비교
   ├─ product/ ingredient/   모델과 저장소 (API 연동 지점)
   ├─ recommendation/  맞춤 추천
   ├─ report/          화장대 보고서
   └─ profile/         마이페이지
```

**화면 구조** — 메인 화면은 모두 쉘(`AppShell`) 안에 있습니다. 헤더(햄버거 서랍 ·
COSMOS 로고 · 마이)와 푸터(화장대/홈/마이 탭)는 쉘이 고정으로 갖고, 각 화면은 자기
AppBar 없이 body 상단의 `ScreenTitle`만 둡니다. 쉘 밖은 로그인 전 진입 흐름뿐입니다.

```
쉘 안 (헤더·푸터 고정)
├─ 화장대 탭   /shelf → add(검색·담기) → product(제품 상세) → ingredient(성분 상세)
├─ 홈 탭       /home → /bsti · /recommendation · /report · /compare
└─ 마이 탭     /profile → edit(프로필 수정)

쉘 밖 (로그인 전)
└─ /splash → /onboarding → 로그인 시트 → profile → concerns → done
```

폰 시안 기준 레이아웃이라 콘텐츠를 최대 480px 중앙 정렬로 제한합니다(`ContentWidth`,
쉘이 일괄 적용). 비교표처럼 넓은 표는 자기 영역 안에서만 가로 스크롤합니다.

## 테스트

```bash
flutter test    # 158개, 환경값 없이 통과
```

| 위치 | 내용 |
|---|---|
| `test/smoke_screens_test.dart` | 12개 화면을 실제로 렌더링해 예외·오버플로우 확인 |
| `test/features/bsti/` | BSTI 데이터 정합성·채점·이름 매칭 |
| `test/features/product/` `ingredient/` | 명세서 예시 JSON 원문으로 파싱 검증 |
| `test/features/report/` `recommendation/` | 적합도·추천 규칙 |
| `test/features/auth/` `onboarding/` | 로그인·프로필 |
| `test/support/fake_repositories.dart` | 가짜 저장소 (`ProviderContainer(overrides: fakeRepos)`) |

샘플 데이터는 `test/` 안에만 둡니다. `lib/`에는 목데이터가 없습니다. 네이버 로그인
목업만 예외이고 의도된 것입니다.

## 문서

| 문서 | 내용 |
|---|---|
| [architecture.md](docs/architecture.md) | 앱 구조와 레이어 |
| [conventions.md](docs/conventions.md) | 네이밍·상태관리·PR 규칙 |
| [api-contract.md](docs/api-contract.md) | 서버 응답 필드와 매핑 계약 |
| [design-system.md](docs/design-system.md) | 색·타이포·컴포넌트 |
| [bsti-spec.md](docs/bsti-spec.md) | BSTI 문항·유형·채점 |
| [auth-setup.md](docs/auth-setup.md) | 카카오·구글 로그인 설정 |