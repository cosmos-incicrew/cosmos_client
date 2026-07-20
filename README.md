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
└─ features/               # 기능별 모듈 (data / presentation)
   ├─ auth/                # 로그인 (게스트 동작, 소셜 UI 뼈대)
   ├─ home/                # 홈 (추천 리스트)
   ├─ search/              # 제품명·성분명 검색
   ├─ product/             # 제품 모델·카드·상세
   └─ profile/             # 마이페이지
```

각 feature는 `data`(모델·저장소)와 `presentation`(화면·위젯·프로바이더)로
나뉩니다. 화면이 늘어나면 이 패턴을 그대로 복제하면 됩니다.

## 실행 방법

> ⚠️ 이 PC에는 아직 Flutter SDK가 설치되어 있지 않습니다.
> [Flutter 설치](https://docs.flutter.dev/get-started/install/windows) 후 진행하세요.

```bash
# 1) 프로젝트 폴더로 이동
cd cosmos_app

# 2) 이 스캐폴드에는 flutter create 의 플랫폼 폴더(android/ios/web)가
#    아직 없습니다. 아래로 현재 폴더에 플랫폼 폴더를 생성합니다.
flutter create .

# 3) 의존성 설치
flutter pub get

# 4) 실행 (Supabase 없이도 게스트 로그인으로 실행됨)
flutter run

# Supabase / API 연동 시 (값 채운 뒤):
flutter run \
  --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbG... \
  --dart-define=API_BASE_URL=https://api.yourservice.com
```

## 현재 동작 범위

- ✅ 게스트 로그인 → 홈 진입 → 검색 → 제품 상세 → 마이페이지 → 로그아웃
- ✅ 하단 탭(홈/마이), 성분 안전도 배지, 목업 데이터 기반 화면
- 🔲 소셜 로그인: 버튼 UI만 배치 (탭 시 "준비 중" 안내). SDK 연동 필요
- 🔲 검색: 샘플 데이터 로컬 필터. 실제 검색 API(BE 담당) 연동 필요
- 🔲 Supabase 스키마 / 실제 제품·성분 데이터 연동

## 다음 작업 (TODO)

코드 내 `TODO:` 주석 위치를 참고하세요.

1. `lib/core/config/env.dart` — Supabase URL/Key, API 주소 채우기
2. `lib/features/auth/data/auth_repository.dart` — 카카오 등 소셜 SDK 연동
3. `lib/features/search/...` — dio 로 검색 API 호출
4. `lib/features/product/data/models/product.dart` — 실제 API 스키마 반영
