/// 환경 설정 값.
///
/// Supabase URL / anon key 등 민감하지 않은 클라이언트 설정을 모읍니다.
/// 실제 값은 `--dart-define` 으로 주입하는 것을 권장합니다.
///
/// 실행 예:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_....
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // TODO: Supabase 프로젝트 URL
  );

  /// 신규 publishable key를 우선하고 전환 기간에는 legacy anon key도 허용합니다.
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  /// BE 팀 담당 검색 API 베이스 URL (Dio 용).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com', // TODO: 실제 API 주소
  );

  /// Supabase 설정이 채워졌는지 여부. 비어 있으면 초기화를 건너뜁니다.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;
}
