# 개발 백엔드 연결 가이드

이 문서는 Flutter 앱을 Cosmos 개발 API에 연결할 때 필요한 설정과 구현 순서를
설명합니다. 환경변수만 넣으면 앱이 자동으로 백엔드 데이터를 표시하는 상태는 아직
아닙니다. 현재는 설정 기반이 준비되어 있고, 인증과 repository 연결 작업이 남아
있습니다.

## 현재 개발 주소

| 항목 | 주소 |
|---|---|
| API base URL | `https://api.35-255-31-62.nip.io` |
| API health | `https://api.35-255-31-62.nip.io/health` |
| Swagger | `https://api.35-255-31-62.nip.io/docs` |

Swagger는 팀 공용 Basic Auth로 보호됩니다. Flutter 앱이 일반 API를 호출할 때는
Basic Auth를 사용하지 않습니다. 인증이 필요한 API에는 Supabase access token을
`Authorization: Bearer <token>` 형식으로 보냅니다.

## 1. 로컬 실행 설정 만들기

저장소 루트에서 예제 파일을 복사합니다.

```bash
cp dart_defines/dev.example.json dart_defines/dev.json
```

`dart_defines/dev.json`에 개발용 Supabase 값을 채웁니다.

```json
{
  "SUPABASE_URL": "https://<project-ref>.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "<publishable-key>",
  "GOOGLE_WEB_CLIENT_ID": "",
  "API_BASE_URL": "https://api.35-255-31-62.nip.io"
}
```

- `SUPABASE_PUBLISHABLE_KEY`는 앱에 넣을 수 있는 공개 클라이언트 키입니다.
- `SUPABASE_SERVICE_ROLE_KEY`, Kakao Admin 키, Langfuse secret 키는 절대 앱에
  넣지 않습니다.
- `API_BASE_URL` 끝에는 `/`를 붙이지 않습니다.
- `dart_defines/dev.json`은 `.gitignore`에 포함되어 있으므로 커밋하지 않습니다.

다음 명령으로 앱을 실행합니다.

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines/dev.json
```

휴대폰이 Wi-Fi가 아닌 외부 네트워크를 사용해도 같은 HTTPS 주소로 접근할 수 있습니다.
먼저 휴대폰 브라우저에서 health 주소를 열어 `{"status":"ok"}`가 보이는지 확인하면
네트워크 문제와 앱 구현 문제를 빠르게 구분할 수 있습니다.

## 2. 현재 연결 상태 이해하기

환경값은 `lib/core/config/env.dart`가 읽고, `lib/core/network/dio_client.dart`가
`API_BASE_URL`을 Dio의 base URL로 사용합니다. 하지만 다음 두 부분은 아직 TODO입니다.

1. 로컬 게스트 로그인은 Supabase 세션을 만들지 않습니다. 따라서 백엔드가 인정하는
   access token이 없습니다.
2. `ProductRepository`와 `IngredientRepository`는 아직 API를 호출하지 않고 빈 결과를
   반환합니다.

즉, `dev.json`을 채우는 것만으로 검색 화면에 데이터가 나타나지는 않습니다. 아래
순서대로 인증과 repository를 연결해야 합니다.

## 3. Supabase 세션을 API 요청에 넣기

먼저 `AuthRepository`의 실제 로그인 구현이 Supabase session을 만들도록 연결합니다.
로컬에서 만든 `guest` 문자열은 백엔드 JWT로 사용할 수 없습니다.

세션이 준비되면 `dio_client.dart`의 request interceptor에서 access token을 넣습니다.

```dart
final token = SupabaseService.auth.currentSession?.accessToken;
if (token != null) {
  options.headers['Authorization'] = 'Bearer $token';
}
```

로그인이 필요한 화면에서 token이 없다면 API를 호출한 뒤 `401`을 처리하기보다 로그인
화면으로 보내는 편이 좋습니다. 만료된 세션은 Supabase SDK가 갱신한 최신
`currentSession` 값을 요청 시점마다 읽어야 합니다.

## 4. repository를 Dio와 연결하기

repository가 `Dio`를 생성하지 않도록 Riverpod의 `dioProvider`를 주입합니다.

```dart
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});
```

`IngredientRepository`도 같은 방식으로 연결합니다. 각 메서드에서는 상대 경로만
사용하고, 응답을 `Product.fromJson` 또는 `Ingredient.fromJson`으로 변환합니다.

```dart
final response = await _dio.get<Map<String, dynamic>>(
  '/api/v1/products/search',
  queryParameters: {'q': query},
);
```

응답의 최상위 구조는 메서드마다 다르므로 `response.data`를 바로 `List`로 단정하지
말고 Swagger의 response schema와 실제 모델을 대조합니다.

## 5. 현재 API와 프론트 요구사항 비교

실행 중인 서버에서 프론트 repository와 바로 연결할 수 있는 조회 API는 일부입니다.

| 프론트 메서드 | 현재 개발 API | 상태 |
|---|---|---|
| `ProductRepository.search` | `GET /api/v1/products/search` | 연결 가능 |
| `IngredientRepository.search` | `GET /api/v1/ingredients/search` | 연결 가능 |
| 제품의 성분 ID 조회 | `GET /api/v1/products/{product_id}/ingredients` | 별도 흐름에서 사용 가능 |
| `ProductRepository.listAll` | 대응 API 없음 | 백엔드 계약 필요 |
| `ProductRepository.getByIngredient` | 대응 API 없음 | 백엔드 계약 필요 |
| `ProductRepository.findByBstiIngredient` | 대응 API 없음 | 백엔드 계약 필요 |
| `IngredientRepository.getByIds` | 동일 응답의 대응 API 없음 | 백엔드 계약 필요 |
| `IngredientRepository.bstiIdsByProducts` | 대응 API 없음 | 백엔드 계약 필요 |

프론트가 최종적으로 필요로 하는 응답 필드와 정렬 규칙은
[API 연동 계약](api-contract.md)을 참고합니다. 백엔드에 없는 API를 프론트에서
추측해 우회 구현하지 말고, 양쪽이 경로와 response schema를 합의한 뒤 구현합니다.

## 6. 실제 요청 확인하기

로그인 후 얻은 Supabase access token으로 앱 구현 전에 API를 직접 확인할 수 있습니다.

```bash
API_URL=https://api.35-255-31-62.nip.io
SUPABASE_ACCESS_TOKEN='로그인 후 받은 access token'

curl --fail --get "$API_URL/api/v1/products/search" \
  --data-urlencode 'q=크림' \
  -H "Authorization: Bearer $SUPABASE_ACCESS_TOKEN"
```

문제가 생기면 상태 코드부터 확인합니다.

| 상태 | 먼저 확인할 것 |
|---|---|
| 연결 실패 | 개발 VM 실행 여부와 `/health` |
| `401` | Supabase 세션 존재 여부, `Bearer` 헤더, token 만료 |
| `422` | query parameter와 request body가 Swagger와 일치하는지 |
| `503` | `/health/ready`와 Supabase 연결 상태 |
| `200`인데 빈 화면 | JSON 필드명, repository 파싱, Riverpod provider 상태 |

## Flutter Web 주의사항

Android와 iOS 앱의 HTTP 요청에는 브라우저 CORS 제한이 없습니다. Flutter Web은
브라우저에서 실행되므로 API 서버가 해당 origin을 허용해야 합니다. 현재 개발 API에는
웹 클라이언트용 CORS 정책이 아직 포함되지 않았으므로 Chrome에서는 요청이 차단될 수
있습니다.

웹 테스트가 필요하면 사용하는 origin을 먼저 정한 뒤 백엔드 CORS 허용 목록을 별도
PR로 추가합니다. 개발 편의를 이유로 인증 API에 무조건적인 `*` 정책을 적용하지
않습니다.

## 연동 완료 기준

- 실제 Supabase 로그인 후 session이 유지됩니다.
- 인증 API 요청에 access token이 자동으로 포함됩니다.
- 제품·성분 검색 결과가 repository 모델로 파싱되어 화면에 표시됩니다.
- `401`, `422`, 네트워크 실패가 사용자에게 이해 가능한 상태로 표시됩니다.
- `flutter test`가 통과하고 실제 Android 또는 iOS 기기에서 확인됩니다.
- 미구현 API가 필요한 화면은 빈 결과로 숨기지 않고 작업 범위가 문서나 이슈에
  남아 있습니다.
