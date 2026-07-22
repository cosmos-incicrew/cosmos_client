/// 환경 설정 값.
///
/// Supabase URL / anon key 등 민감하지 않은 클라이언트 설정을 모읍니다.
/// 실제 값은 `--dart-define` 으로 주입하는 것을 권장합니다.
///
/// 실행 예:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhb....
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // TODO: Supabase 프로젝트 URL
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '', // TODO: Supabase anon key
  );

  /// BE 팀 담당 검색 API 베이스 URL (Dio 용).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com', // TODO: 실제 API 주소
  );

  /// 구글 로그인용 **웹** 클라이언트 ID (Google Cloud 등록값).
  ///
  /// 안드로이드 클라이언트 ID가 아니라 웹 쪽을 넣는다 — google_sign_in 은 이 값을
  /// serverClientId 로 받아 Supabase 가 검증할 수 있는 ID 토큰을 발급받는다.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// 카카오 로그인 후 앱으로 돌아올 딥링크.
  ///
  /// AndroidManifest 의 intent-filter scheme/host 와 **글자까지 같아야** 한다.
  /// 다르면 브라우저에서 로그인은 끝나는데 앱으로 안 돌아온다.
  static const String authRedirectUrl = 'cosmos://login-callback';

  /// Supabase 설정이 채워졌는지 여부. 비어 있으면 초기화를 건너뜁니다.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// 구글 로그인을 시도할 수 있는지. 비어 있으면 버튼이 안내만 띄운다.
  static bool get hasGoogleSignIn =>
      hasSupabase && googleWebClientId.isNotEmpty;
}
