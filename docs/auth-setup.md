# 소셜 로그인 설정 검토 체크리스트 (구글·카카오)

앱과 서버 코드는 이미 구현돼 있다. 로그인이 안 된다면 원인은 아래 콘솔 설정 중 하나다.
값이 **한 글자라도** 다르면 실패하므로, 이 문서의 값을 그대로 복사해 대조한다.

## 이 프로젝트의 고정값

| 항목 | 값 |
|---|---|
| Supabase 프로젝트 ref | `oevxfczitfuuataugxay` (region ap-northeast-2) |
| Supabase URL | `https://oevxfczitfuuataugxay.supabase.co` |
| OAuth 콜백 URL (구글·카카오 콘솔에 넣는 값) | `https://oevxfczitfuuataugxay.supabase.co/auth/v1/callback` |
| 앱 딥링크 (Supabase 대시보드에 넣는 값) | `cosmos://login-callback` |
| 안드로이드 패키지명 | `com.cosmos.app` |
| 디버그 키 SHA-1 | `DA:1B:2C:B0:56:C4:56:DB:B4:5D:D8:4C:82:24:2B:43:76:E9:7C:17` |
| 디버그 키 SHA-256 | `92:BB:8D:FB:9A:19:C3:97:43:4E:D1:E4:86:41:84:5C:D2:72:74:0B:5B:0D:95:CA:D8:C7:D4:1E:63:6B:48:8D` |

> SHA-1 은 각자 PC 의 `~/.android/debug.keystore` 에서 나온다. **팀원마다 다르다.**
> 위 값은 민경 PC 기준이므로, 다른 팀원이 디버그 빌드로 구글 로그인을 하려면
> 각자 지문을 뽑아 Google Cloud 안드로이드 클라이언트에 추가로 등록해야 한다.
>
> ```bash
> # JDK 가 있으면
> keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
> # JDK 가 없으면 (최근 debug.keystore 는 PKCS#12 라 openssl 로 읽힌다)
> openssl pkcs12 -in ~/.android/debug.keystore -passin pass:android -nokeys -legacy \
>   | openssl x509 -noout -fingerprint -sha1
> ```

## 1. Supabase 대시보드

### Authentication → URL Configuration
- [ ] **Redirect URLs** 에 `cosmos://login-callback` 이 있다.
      → 없으면 카카오 로그인 후 브라우저에서 앱으로 못 돌아온다. (구글은 네이티브라 무관)

### Authentication → Providers → Google
- [ ] Enabled = ON
- [ ] **Client IDs** 에 **웹 클라이언트 ID 와 안드로이드 클라이언트 ID 를 쉼표로 나열**
      → 네이티브 로그인은 안드로이드 클라이언트 ID 로 서명된 ID 토큰을 보낸다.
        웹 것만 넣으면 `Unacceptable audience` 로 거부된다.
- [ ] Client Secret = 웹 클라이언트의 시크릿
- [ ] `Skip nonce check` 는 **안 켜도 된다** (iOS 전용 항목, 이 앱은 안드로이드 전용)

### Authentication → Providers → Kakao
- [ ] Enabled = ON
- [ ] Client ID = 카카오 **REST API 키** (네이티브 앱 키 아님)
- [ ] Client Secret = 카카오 **Client Secret 코드**
- [ ] 카카오 앱이 비즈 앱이 아니라면 **Allow users without an email = ON**
      → 이메일 없는 계정 생성을 허용한다. 다만 이것만으로는 로그인이 안 된다 — 아래 참고.

> **`account_email` 스코프 문제 (2026-07-21 해결)**
>
> Supabase는 카카오 authorize 요청에 `account_email`을 **항상** 붙인다.
> 그런데 이 동의항목은 **비즈 앱만** 설정할 수 있어서, 일반 앱에서는 카카오가
> `invalid_scope`로 로그인을 거부한다. 실제로 관측된 콜백:
>
> ```
> cosmos://login-callback?error=invalid_scope&error_description=Invalid+scope:+account_email
> ```
>
> `Allow users without an email`은 **토큰 교환 이후** 단계라 이걸 못 막는다.
> Supabase 대시보드에도 이 스코프를 빼는 설정이 없다.
>
> 해결: `signInWithOAuth`에 쿼리 파라미터 **`scope`(단수)** 를 실어 목록을 통째로 교체한다.
> 이름 있는 인자 `scopes`(복수)는 기본 목록에 **덧붙기만** 해서 소용없다.
>
> ```dart
> queryParams: const {'scope': 'profile_nickname profile_image'},
> ```
>
> 검증 결과 (`/auth/v1/authorize` 응답의 Location 헤더):
>
> | 요청 | 카카오로 나가는 scope |
> |---|---|
> | 기본 | `account_email profile_image profile_nickname` |
> | `scopes=profile_nickname` | `account_email profile_image profile_nickname profile_nickname` |
> | `scope=profile_nickname profile_image` | `profile_nickname profile_image` ✅ |
>
> 이 방식이면 **비즈 앱 전환도, 카카오 SDK 도입도 필요 없다.**

## 2. Google Cloud Console

### OAuth 클라이언트 — 웹 애플리케이션
- [ ] 승인된 리디렉션 URI에 `https://oevxfczitfuuataugxay.supabase.co/auth/v1/callback`
- [ ] 이 클라이언트 ID 를 `dart_defines/dev.json` 의 `GOOGLE_WEB_CLIENT_ID` 에 넣었다
      (앱이 `serverClientId` 로 쓰는 값이 이것이다 — 안드로이드 것이 아니다)

### OAuth 클라이언트 — Android
- [ ] 패키지 이름 = `com.cosmos.app`
- [ ] SHA-1 인증서 지문 = 위 표의 값 (팀원별로 추가 등록)
- [ ] 이 클라이언트 ID 를 Supabase Google provider 의 Client IDs 에 함께 넣었다

### OAuth 동의 화면
- [ ] 게시 상태가 `테스트` 라면 **테스트 사용자에 로그인할 계정이 등록**돼 있다
      → 미등록 계정은 `403 access_denied` 로 막힌다. 발표 시연 계정을 미리 넣어둘 것.

## 3. Kakao Developers

- [ ] 앱 설정 → 앱 → 플랫폼 키 → **Kakao Login Redirect URI** 에
      `https://oevxfczitfuuataugxay.supabase.co/auth/v1/callback`
- [ ] 앱 설정 → 앱 → 플랫폼 → **Web** 플랫폼에 `https://oevxfczitfuuataugxay.supabase.co` 등록
- [ ] 제품 설정 → 카카오 로그인 → **활성화 설정 = ON**
- [ ] 제품 설정 → 카카오 로그인 → **보안 → Client Secret 코드 생성 + 활성화 = 사용함**
      → 생성만 하고 활성화를 안 하면 Supabase 가 보낸 시크릿이 거부된다.
- [ ] 동의항목: `profile_nickname`, `profile_image` 설정.
      `account_email` 은 비즈 앱만 가능하며 **설정하지 않는다** — 위 `scope` 단수 파라미터로 우회한다.

> 카카오 **네이티브 앱 키와 키 해시는 필요 없다.** 이 앱은 카카오 SDK 를 쓰지 않고
> Supabase 웹 OAuth 로만 처리한다 (`auth_repository.dart` 주석 참고).

## 4. 앱 실행

```bash
cd cosmos_client
cp dart_defines/dev.example.json dart_defines/dev.json   # 최초 1회
# dev.json 의 GOOGLE_WEB_CLIENT_ID 를 채운 뒤
flutter run --dart-define-from-file=dart_defines/dev.json
```

`dart_defines/dev.json` 은 gitignore 대상이다. 커밋하지 않는다.

## 5. 동작 확인

1. 로그인 시트에서 구글 → 계정 선택 → 홈 진입
2. 로그인 시트에서 카카오 → 브라우저 → 동의 → 앱 복귀 → 홈 진입
3. 성공했는지는 DB 로 확인한다:
   ```sql
   select provider, created_at from auth.identities order by created_at desc;
   ```

**2026-07-21 실기기 검증 (갤럭시 A90 5G, Android 12)**

- 카카오 로그인 **성공** — `auth.users` 1건 생성 (provider=kakao, email 빈 값).
  딥링크 `cosmos://login-callback?code=...` 복귀까지 정상.
- 구글 로그인 **미검증** — 아직 시도 기록 없음.
- 딥링크 경로 자체는 아래로 단독 검증 가능하다 (OAuth 없이 전달만 확인):
  ```bash
  adb shell am start -a android.intent.action.VIEW \
    -c android.intent.category.BROWSABLE -d "cosmos://login-callback"
  # logcat 에 app_links 의 "Handled intent" 가 찍히면 정상
  ```

## 기기 없이 설정만 검증하기

콘솔 설정이 맞는지는 안드로이드 기기 없이도 아래로 확인할 수 있다.
실제 로그인(네이티브 ID 토큰·딥링크 복귀)은 기기가 있어야 하지만, 설정 오류는 여기서 거의 다 걸린다.

```bash
KEY=$(python3 -c "import json;print(json.load(open('dart_defines/dev.json'))['SUPABASE_ANON_KEY'])")

# 1. provider 활성화 상태 — google / kakao 가 true 여야 한다
curl -s "https://oevxfczitfuuataugxay.supabase.co/auth/v1/settings" -H "apikey: $KEY" \
  | python3 -c "import json,sys;e=json.load(sys.stdin)['external'];print({k:e[k] for k in ('google','kakao')})"

# 2. OAuth 진입 — 최종 URL 에 signin/oauth/error 나 KOE 코드가 없어야 한다
export LC_ALL=C
for P in google kakao; do
  LOC=$(curl -s -o /dev/null -D - \
    "https://oevxfczitfuuataugxay.supabase.co/auth/v1/authorize?provider=$P&redirect_to=cosmos%3A%2F%2Flogin-callback" \
    -H "apikey: $KEY" | grep -i "^location:" | sed 's/^[Ll]ocation: //' | tr -d '\r')
  echo "$P → $(curl -s -L -o /dev/null -w '%{url_effective}' "$LOC" | cut -c1-80)"
done
```

2번의 `location` 헤더에 실린 `client_id` 가 **Supabase 에 등록된 첫 번째 Client ID** 다.
구글은 여기가 반드시 **웹** 클라이언트여야 한다 (모바일이 먼저면 시크릿이 없어 웹 흐름이 깨진다).

**2026-07-21 검증 결과**: provider 2종 활성화 ✓ / 구글 웹 ID 우선 ✓ / 구글·카카오 동의화면 정상 진입 ✓.
이 시점까지 `auth.identities` 는 0건 — 실제 로그인은 안드로이드 기기 확보 후 검증해야 한다.

## 증상별 원인

| 증상 | 볼 곳 |
|---|---|
| 버튼을 눌러도 "설정이 아직 없습니다" | `dart_defines/dev.json` 미주입 또는 `GOOGLE_WEB_CLIENT_ID` 공란 |
| 구글: 계정 선택 후 `Unacceptable audience` | Supabase Google provider 의 Client IDs 에 안드로이드 클라이언트 ID 누락 |
| 구글: `ApiException: 10` | Google Cloud 안드로이드 클라이언트의 SHA-1 또는 패키지명 불일치 |
| 구글: `403 access_denied` | OAuth 동의 화면이 테스트 모드 + 계정 미등록 |
| 카카오: 브라우저에서 로그인은 되는데 앱으로 안 돌아옴 | Supabase Redirect URLs 에 `cosmos://login-callback` 누락 |
| 카카오: `KOE006` | 카카오 Redirect URI 불일치 |
| 카카오: 동의 후 에러 페이지 | Client Secret 미활성화, 또는 이메일 없는 사용자 차단 |
| 카카오: `invalid_scope` / `Invalid scope: account_email` | `signInWithOAuth` 의 `scope`(단수) 파라미터 누락 — 위 §3 참고 |
| 로그인은 되는데 서버 API 가 **모두** 401 | 서버가 토큰을 HS256으로 검증하고 있지 않은지 확인. 이 프로젝트는 ES256 서명이라 JWKS 공개키로 검증해야 한다 (`app/core/auth.py`) |
| 실기기에서 서버 API 가 연결 실패 | `dart_defines/dev.json` 의 `API_BASE_URL` 이 `10.0.2.2`(에뮬레이터 전용)면 실기기에선 못 닿는다 → PC 의 LAN IP 로 바꾸고, 서버를 `--host 0.0.0.0` 으로 띄운다 |
| 회원가입 후 프로필 저장 실패 | `supabase/migrations` 가 원격에 다 적용됐는지 확인 (`nickname` 컬럼 누락 사례 있음) |
