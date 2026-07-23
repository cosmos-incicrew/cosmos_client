# Vercel 배포 가이드

이 문서는 프론트 배포 담당자가 Cosmos Flutter Web을 기존 Vercel 프로젝트에
배포하는 순서를 설명합니다. 처음 배포하더라도 위에서부터 차례로 진행하면 됩니다.

현재 Production 주소는 다음과 같습니다.

```text
https://cosmos-incicrew.vercel.app
```

이 가이드는 **로컬에서 Flutter Web을 빌드한 뒤 결과물을 기존 Vercel 프로젝트에
올리는 방식**을 기준으로 합니다. Flutter의 `String.fromEnvironment` 값은 빌드할 때
고정되므로, Vercel Dashboard에 같은 이름의 환경변수만 추가해도 이미 만들어진
JavaScript에는 반영되지 않습니다.

## 전체 순서

1. 필요한 접근 권한과 공개 설정값을 받습니다.
2. 로컬 `prod.json`을 만듭니다.
3. Supabase의 웹 주소 설정을 확인합니다.
4. 테스트와 Flutter Web 빌드를 한 번에 실행합니다.
5. 기존 Vercel 프로젝트에 Production 배포합니다.
6. 사이트, 라우팅, API CORS를 확인합니다.

## 1. 시작 전에 준비하기

다음 항목이 필요합니다.

- `cosmos_client` 저장소 접근 권한
- 기존 Vercel `cosmos-incicrew` 프로젝트 접근 권한
- Flutter `3.27` 이상(Dart `3.6` 이상)
- Node.js와 Vercel CLI
- Supabase Dashboard에서 publishable key를 확인할 권한

버전을 확인합니다.

```bash
flutter --version
node --version
vercel --version
```

`vercel` 명령이 없다면 설치하고 로그인합니다.

```bash
npm install --global vercel
vercel login
```

## 2. 배포 설정 파일 만들기

저장소 루트에서 예제 파일을 복사합니다.

```bash
cp dart_defines/prod.example.json dart_defines/prod.json
```

`dart_defines/prod.json`은 다음 모양이어야 합니다.

```json
{
  "SUPABASE_URL": "https://oevxfczitfuuataugxay.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_...",
  "GOOGLE_WEB_CLIENT_ID": "",
  "API_BASE_URL": "https://api.35-255-31-62.nip.io"
}
```

Supabase Dashboard의 `Project Settings → API Keys`에서 publishable key를 확인해
`SUPABASE_PUBLISHABLE_KEY`에 넣습니다. `prod.json`은 Git에서 무시되므로 커밋하지
않습니다.

다음 값은 프론트에 넣으면 안 됩니다.

- Supabase secret 또는 `service_role` 키
- Kakao Admin 키
- Langfuse secret 키
- GCP 서비스 계정 키

브라우저에 포함되는 Flutter Web 번들은 사용자가 내려받을 수 있습니다. Vercel
Dashboard에서 값을 숨김 처리해도 빌드 결과에 포함된 클라이언트 설정은 비밀이
아닙니다. 프론트에는 publishable key만 사용합니다.

## 3. Supabase 웹 주소 확인하기

소셜 로그인, 이메일 인증 또는 비밀번호 재설정을 구현할 때 필요한 설정입니다.
아직 해당 기능을 사용하지 않더라도 Production 주소를 먼저 맞춰 두면 됩니다.

1. Supabase Dashboard에서 `cosmos` 프로젝트를 엽니다.
2. `Authentication → URL Configuration`으로 이동합니다.
3. `Site URL`을 다음 값으로 설정합니다.

   ```text
   https://cosmos-incicrew.vercel.app
   ```

4. Production Redirect URL에는 실제 로그인 복귀 경로를 정확히 등록합니다. 현재
   루트로 돌아오게 구현한다면 다음 값을 사용합니다.

   ```text
   https://cosmos-incicrew.vercel.app/
   ```

5. 로컬 웹 로그인을 테스트할 때만 다음 값을 Additional Redirect URLs에 추가합니다.

   ```text
   http://localhost:8123/**
   ```

Production에서는 넓은 wildcard보다 실제 redirect 경로를 정확히 등록합니다. Vercel
Preview 주소의 로그인까지 필요하다면 그때 Preview 도메인 규칙을 별도로 추가합니다.

## 4. 테스트하고 빌드하기

저장소 루트에서 다음 명령 하나를 실행합니다.

```bash
./scripts/build-web.sh
```

스크립트는 다음 작업을 순서대로 수행합니다.

1. 패키지 설치
2. `flutter analyze`
3. `flutter test`
4. Production 설정을 넣은 release 웹 빌드
5. Flutter의 클라이언트 라우팅을 위한 Vercel rewrite 복사

중간 단계가 하나라도 실패하면 배포하지 말고 원인을 수정합니다. 성공하면
`build/web`에 배포 파일이 만들어집니다.

빌드에 올바른 주소가 들어갔는지 확인합니다.

```bash
rg -F "https://api.35-255-31-62.nip.io" build/web/main.dart.js
rg -F "https://oevxfczitfuuataugxay.supabase.co" build/web/main.dart.js
```

두 명령 모두 문자열을 찾아야 합니다. 찾지 못하면 `prod.json`과 빌드 명령을 다시
확인합니다.

## 5. 기존 Vercel 프로젝트에 배포하기

빌드 결과 폴더로 이동합니다.

```bash
cd build/web
```

처음 배포하는 PC라면 기존 프로젝트에 연결합니다.

```bash
vercel link
```

질문이 나오면 새 프로젝트를 만들지 말고, 팀과 기존
`cosmos-incicrew` 프로젝트를 선택합니다. 연결이 끝나면 Production으로 배포합니다.

```bash
vercel deploy --prod
```

명령이 출력한 Production URL이 아래 주소인지 확인합니다.

```text
https://cosmos-incicrew.vercel.app
```

다른 새 프로젝트 주소가 나왔다면 Production으로 사용하지 말고 Vercel Dashboard에서
연결한 project와 domain을 확인합니다.

## 6. 배포 후 확인하기

### 사이트와 라우팅

브라우저 시크릿 창에서 두 주소를 직접 엽니다.

```text
https://cosmos-incicrew.vercel.app/
https://cosmos-incicrew.vercel.app/home
```

둘 다 Vercel 404가 아니라 앱을 표시해야 합니다. `/home` 새로고침이 404라면
`build/web/vercel.json`이 배포에 포함되었는지 확인합니다.

### 백엔드 상태

브라우저에서 다음 주소를 열어 `{"status":"ok"}`가 보이는지 확인합니다.

```text
https://api.35-255-31-62.nip.io/health
```

터미널에서는 Vercel origin에 대한 CORS preflight를 확인할 수 있습니다.

```bash
curl --include --request OPTIONS \
  'https://api.35-255-31-62.nip.io/api/v1/products/search' \
  --header 'Origin: https://cosmos-incicrew.vercel.app' \
  --header 'Access-Control-Request-Method: GET' \
  --header 'Access-Control-Request-Headers: authorization,content-type'
```

정상이라면 상태가 `200`이고 다음 응답 헤더가 포함됩니다.

```text
access-control-allow-origin: https://cosmos-incicrew.vercel.app
```

`405`가 나오면 CORS가 포함된 백엔드 버전이 아직 배포되지 않은 상태입니다.

### 브라우저 확인

Chrome 개발자 도구의 `Network`와 `Console`을 엽니다.

- `CORS policy` 오류가 없어야 합니다.
- API 요청 주소가 `api.35-255-31-62.nip.io`여야 합니다.
- 인증 API 요청에는 `Authorization: Bearer ...`가 있어야 합니다.

현재 repository와 소셜 로그인에는 별도 구현 작업이 남아 있습니다. 사이트가 정상
배포되었지만 검색 결과가 비어 있는 것은 Vercel 배포 실패와 다른 문제입니다.
[백엔드 연결 가이드](backend-connection.md)의 완료 범위를 이어서 확인합니다.

## 7. 문제가 생기면

| 증상 | 확인할 곳 |
|---|---|
| `flutter` 명령이 없음 | Flutter SDK 설치와 PATH |
| 빌드에서 설정 파일 오류 | `dart_defines/prod.json` 존재 여부와 JSON 문법 |
| Vercel에 새 주소가 생김 | 기존 `cosmos-incicrew` project에 link했는지 |
| `/home` 새로고침이 404 | `build/web/vercel.json` 포함 여부 |
| API preflight가 `405` | 백엔드 CORS 버전 배포 여부 |
| API가 `401` | Supabase 세션과 Bearer token |
| 화면 데이터가 계속 비어 있음 | repository API 구현과 response adapter |

직전 버전으로 되돌려야 한다면 Vercel Dashboard의 `Deployments`에서 마지막 정상
배포를 선택해 Production으로 다시 지정합니다. 문제가 있는 빌드를 수정한 뒤 같은
절차로 새로 배포합니다.

## 참고 문서

- [Flutter Web release build](https://docs.flutter.dev/deployment/web)
- [Vercel SPA rewrite 설정](https://vercel.com/docs/project-configuration/vercel-json#rewrites)
- [Supabase Auth Redirect URL 설정](https://supabase.com/docs/guides/auth/redirect-urls)
