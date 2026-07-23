# cosmos_client

화장품 성분 기반 추천 앱 — Flutter 클라이언트 (프론트)

백엔드는 별도 저장소 [cosmos_server](https://github.com/cosmos-incicrew/cosmos_server)
(FastAPI)이며, 앱은 Supabase Auth로 로그인해 JWT를 받아 서버 API를 호출한다.
설계·규칙은 [docs/architecture.md](docs/architecture.md)·[docs/conventions.md](docs/conventions.md) 참고.

> **⚠️ 지금 앱을 켜면 검색·추천·보고서가 빈 화면입니다.**
> 버그가 아닙니다. 프론트에는 데이터가 없고, 백엔드 연동을 기다리는 상태입니다.
> BSTI 검사와 게스트 로그인은 지금도 정상 동작합니다.
> 연동 방법은 아래 [백엔드 연동](#백엔드-연동) 참고.

## 기술 스택

| 구분 | 사용 기술 |
|------|-----------|
| 프레임워크 | Flutter (Dart) |
| 디자인 | Material 3 + cosmos 커스텀 테마 |
| 상태관리 | Riverpod (`flutter_riverpod`) |
| 라우팅 | `go_router` |
| 네트워킹 | `supabase_flutter` + `dio` |
| 이미지 로딩 | `cached_network_image` |
| 로컬 저장소 | Hive + `flutter_secure_storage` |
| 로그인 | Supabase Auth OAuth (구글·카카오) + 게스트 |

## 폴더 구조

```
lib/
├─ main.dart               # 진입점 (Hive/Supabase 초기화)
├─ app/                    # 앱 전역 (테마·라우터·루트 위젯)
│  ├─ app.dart             # MaterialApp.router
│  ├─ router/              # go_router 설정 + 하단탭 쉘
│  └─ theme/               # 색상·타이포·에셋 경로
├─ core/                   # 공용 인프라 (feature 간 공유)
│  ├─ config/              # Env (dart-define)
│  ├─ network/             # Supabase / Dio 클라이언트
│  ├─ storage/             # Hive + secure storage
│  ├─ utils/               # 공용 유틸
│  └─ widgets/             # 공통 위젯 (PixelBox 등)
└─ features/               # 기능별 모듈
   ├─ splash/              # 앱 시작 화면 (GIF 로고 + START)
   ├─ onboarding/          # 온보딩 + 프로필(닉네임·나이·성별·피부고민)
   ├─ auth/                # 로그인 (게스트 동작, 소셜은 미구현)
   ├─ home/                # 홈 (메뉴 그리드)
   ├─ bsti/                # 피부 MBTI 검사 ★ 평탄 구조 (아래 설명)
   ├─ my_shelf/            # 제품·성분 검색 → 상세 (내 화장대)
   ├─ product/             # 제품 모델 + 저장소
   ├─ ingredient/          # 성분 모델 + 저장소
   ├─ recommendation/      # 맞춤 추천 (유형·고민·기피 반영)
   ├─ report/              # 화장대 보고서 (적합도 + 부족 성분)
   └─ profile/             # 마이페이지
```

**구조 규칙 — feature 폴더는 두 가지 패턴이 섞여 있습니다.**

| 패턴 | 해당 feature | 설명 |
|---|---|---|
| 계층형 (기본) | bsti 외 전부 | `data/`(모델·저장소·프로바이더) + `presentation/`(화면·위젯) |
| 평탄형 | **bsti** | 폴더 없이 파일을 한 곳에. 데이터·엔진·화면이 모두 `lib/features/bsti/` 바로 아래 |

> BSTI는 관련 파일을 한 폴더에서 보려고 일부러 평탄하게 뒀습니다. 다른 feature는 계층형을 따르세요.

## 백엔드 연동

**프론트에는 데이터가 없습니다.** 화면은 저장소(repository)만 보고,
저장소는 지금 빈 결과를 돌려줍니다. **저장소 메서드 본문만 채우면** 연동이 끝납니다.
화면 코드는 손대지 않아도 됩니다.

```bash
grep -rn "TODO(BE)" lib/     # 연동 지점 전체 (엔드포인트 7개)
```

스키마·응답 예시·주의사항은 **[docs/api-contract.md](docs/api-contract.md)** 에 정리돼 있습니다.

| 저장소 | 파일 |
|---|---|
| `ProductRepository` | `lib/features/product/data/product_repository.dart` |
| `IngredientRepository` | `lib/features/ingredient/data/ingredient_repository.dart` |

**⚠️ 놓치기 쉬운 것 2가지** (둘 다 에러 없이 조용히 잘못 동작합니다)

1. **`getByIds` 는 요청한 id 순서를 지켜야 합니다.** 제품 상세가 앞 3개를
   "대표성분"으로 쓰기 때문에, SQL `WHERE id IN (...)` 처럼 순서가 섞이면
   대표성분이 조용히 바뀝니다.
2. **`bsti_ingredient_id` 가 BSTI 기능의 연결고리입니다.** 이 값이 없으면
   보고서 적합도와 추천이 조용히 빈 화면이 됩니다.
   앱이 아는 id는 `kBstiIngredients` 의 34개입니다.

> BSTI 데이터(성분 34 · 유형 16 · 문항 20)는 **프론트가 들고 있습니다.**
> 백엔드가 내려줄 필요 없습니다. 서버는 제품·성분만 주면 되고,
> 연결은 `bsti_ingredient_id` 하나로 이뤄집니다.

## 테스트

```bash
flutter test        # 전체 (92개)
```

테스트는 전부 **`test/`** 아래에 `lib/` 구조를 그대로 미러링해 둡니다.
(`flutter test` 가 자동으로 찾으므로 별도 등록이 필요 없습니다)

| 위치 | 내용 |
|---|---|
| `test/features/bsti/` | BSTI 데이터 정합성·채점 엔진 (20개) |
| `test/features/report/` | 보고서 적합도·부족 성분 추천 |
| `test/features/recommendation/` | 유형·고민·기피 반영 검증 |
| `test/smoke_screens_test.dart` | **9개 화면을 실제로 띄워** 예외·오버플로우 검증 |
| `test/support/fake_repositories.dart` | 테스트용 가짜 저장소 + 샘플 데이터 |

**샘플 데이터는 `test/` 안에만 둡니다.** `lib/` 에는 목데이터를 두지 않습니다.
테스트에서 데이터가 필요하면 저장소 프로바이더를 override 하세요:

```dart
final container = ProviderContainer(overrides: fakeRepos);
```

## 실행 방법

```bash
cd cosmos_app
flutter pub get

# 실행 (Supabase 없이도 게스트 로그인으로 동작)
flutter run

# 웹으로 띄우기
flutter run -d chrome

# 같은 네트워크의 다른 기기에서도 열려면
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8123
#   → 이 PC: http://localhost:8123 / 다른 기기: http://<이 PC IP>:8123
#   (방화벽에서 해당 포트를 열어야 할 수 있음)

# Supabase / API 연동 시 (값 채운 뒤):
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
  --dart-define=API_BASE_URL=https://api.yourservice.com

# 또는 dart_defines/dev.example.json을 dev.json으로 복사하고 값을 채운 뒤:
flutter run --dart-define-from-file=dart_defines/dev.json
```

## 현재 동작 범위

**백엔드 없이 지금 동작하는 것**

- ✅ 스플래시(GIF 로고) → 온보딩 → 프로필 등록 → 로그인 시트 → 홈
- ✅ **BSTI 검사 전 과정** — 20문항 설문 → 채점 → 결과(유형별 고양이·성분·자차).
  앱이 자체 채점하며, 결과는 세션 동안 저장돼 재진입 시 바로 결과 화면으로 갑니다.
  자세한 설계는 [docs/bsti-spec.md](docs/bsti-spec.md)
- ✅ 게스트 로그인
- ✅ 화장대에 담기 / 선호·기피 구분 (로컬 저장)

**백엔드가 붙어야 채워지는 것** (지금은 빈 화면)

- 🔲 제품·성분 검색 — `ProductRepository.search` / `IngredientRepository.search`
- 🔲 맞춤 추천 — `ProductRepository.listAll`
- 🔲 화장대 보고서 적합도·추천 — `bstiIdsByProducts` / `findByBstiIngredient`
- 🔲 제품·성분 상세의 성분 목록 — `getByIds`

**아직 구현 안 된 것**

- 🔲 소셜 로그인 (카카오·네이버·구글·애플) — 전부 `UnimplementedError`.
  버튼을 누르면 크래시 대신 "준비 중" 안내가 뜹니다. SDK 연동 필요
- 🔲 제품 이미지 — 실서비스는 제휴/직접 확보 이미지 필요

## 다음 작업 (TODO)

```bash
grep -rn "TODO(BE)" lib/     # 백엔드 연동 지점
grep -rn "TODO:" lib/        # 그 외 남은 작업
```

1. `lib/core/config/env.dart` — Supabase URL/Key, API 주소 채우기
2. `lib/features/product/data/product_repository.dart` — 제품 API 연동
3. `lib/features/ingredient/data/ingredient_repository.dart` — 성분 API 연동
4. `lib/features/auth/data/auth_repository.dart` — 소셜 로그인 SDK 연동
