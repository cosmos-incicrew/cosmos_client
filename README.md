# cosmos_client

화장품 성분 기반 추천 앱 — Flutter 클라이언트 (기초 프론트 스캐폴드)

백엔드는 별도 저장소 [cosmos_server](https://github.com/cosmos-incicrew/cosmos_server)
(FastAPI)이며, 앱은 Supabase Auth로 로그인해 JWT를 받아 서버 API를 호출한다.
설계·규칙은 [docs/architecture.md](docs/architecture.md)·[docs/conventions.md](docs/conventions.md) 참고.

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
│  └─ theme/               # 색상·Material3 테마
├─ core/                   # 공용 인프라 (feature 간 공유)
│  ├─ config/              # Env (dart-define)
│  ├─ network/             # Supabase / Dio 클라이언트
│  ├─ storage/             # Hive + secure storage
│  └─ widgets/             # 공통 위젯 (로딩·에러·빈 상태)
│  └─ mock/                # ⚠️ 목데이터 (백엔드 연동 시 폴더째 삭제)
└─ features/               # 기능별 모듈
   ├─ splash/              # 앱 시작 화면 (GIF 로고 + START)
   ├─ onboarding/          # 온보딩 슬라이드
   ├─ auth/                # 로그인 (게스트 동작, 소셜 UI 뼈대)
   ├─ home/                # 홈 (검색바 + 메뉴 그리드)
   ├─ bsti/                # 피부 MBTI 검사 ★ 평탄 구조 (아래 설명)
   ├─ my_shelf/            # 제품·성분 검색 → 상세 (내 화장대)
   ├─ product/             # 제품 모델
   ├─ ingredient/          # 성분 모델
   ├─ recommendation/      # 맞춤 추천
   └─ profile/             # 마이페이지
```

**구조 규칙 — feature 폴더는 두 가지 패턴이 섞여 있습니다.**

| 패턴 | 해당 feature | 설명 |
|---|---|---|
| 계층형 (기본) | bsti 외 전부 | `data/`(모델·저장소) + `presentation/`(화면·위젯) |
| 평탄형 | **bsti** | 폴더 없이 파일을 한 곳에. 데이터·엔진·화면·테스트가 모두 `lib/features/bsti/` 바로 아래 |

> BSTI는 관련 파일을 한 폴더에서 보려고 일부러 평탄하게 뒀습니다. 다른 feature는 계층형을 따르세요.

## 테스트

```bash
flutter test        # 전체 (39개) — 아래 이유로 이 한 줄이면 충분
```

**주의**: 테스트가 두 곳에 있습니다.

| 위치 | 파일 | 비고 |
|---|---|---|
| `test/` | `widget_test.dart` | 모델 단위 테스트 |
| `test/` | `all_lib_tests_test.dart` | **진입점** — lib 안 테스트를 모아 실행 |
| `lib/features/bsti/` | `bsti_*_test.dart` (4개) | 소스 옆에 둔 테스트 |
| `lib/features/my_shelf/.../` | `shelf_search_test.dart` | 소스 옆에 둔 테스트 |

`flutter test`는 `test/` 폴더만 자동 실행하므로, lib 안 테스트는 **진입점
(`all_lib_tests_test.dart`)이 불러와야** 함께 돌아갑니다.
**lib에 테스트를 추가하면 그 진입점에도 꼭 등록하세요.** 안 하면 조용히 누락됩니다.

## 실행 방법

```bash
cd cosmos_app
flutter pub get

# 실행 (Supabase 없이도 게스트 로그인으로 동작)
flutter run

# 웹으로 띄우기 (폰 프레임으로 보임)
flutter run -d chrome

# 같은 네트워크의 다른 기기에서도 열려면
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8123
#   → 이 PC: http://localhost:8123 / 다른 기기: http://<이 PC IP>:8123
#   (방화벽에서 해당 포트를 열어야 할 수 있음)

# Supabase / API 연동 시 (값 채운 뒤):
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbG... \
  --dart-define=API_BASE_URL=https://api.yourservice.com
```

## 현재 동작 범위

- ✅ 스플래시(GIF 로고) → 온보딩 → 로그인 시트(모달) → 홈
- ✅ **BSTI 검사 전 과정** — 20문항 설문 → 채점 → 결과(유형별 고양이·성분·자차).
  백엔드 없이 앱이 자체 채점. 자세한 설계는 [docs/bsti-spec.md](docs/bsti-spec.md)
- ✅ 제품·성분 검색 → 상세 (권장 피부타입을 BSTI 데이터로 실제 매칭)
- 🔲 소셜 로그인: 버튼 UI만 배치 (탭 시 "준비 중" 안내). SDK 연동 필요
- 🔲 검색·추천: **목데이터** 로컬 필터. 실제 API 연동 필요
- 🔲 제품 이미지: 목데이터용. 실서비스는 제휴/직접 확보 이미지 필요

## 목데이터

개발용 가짜 데이터는 **`lib/core/mock/`** 한 곳에만 있습니다.

백엔드 연동 시:
1. `lib/core/mock/` 폴더 삭제
2. `mockProducts` / `mockIngredients` 참조처를 실제 API로 교체
3. `flutter analyze`로 남은 참조 확인

## 다음 작업 (TODO)

코드 내 `TODO:` 주석 위치를 참고하세요.

1. `lib/core/config/env.dart` — Supabase URL/Key, API 주소 채우기
2. `lib/features/auth/data/auth_repository.dart` — 카카오 등 소셜 SDK 연동
3. `lib/features/my_shelf/...` — 목데이터 → 실제 검색 API 호출
4. `lib/features/product/data/models/product.dart` — 실제 API 스키마 반영
