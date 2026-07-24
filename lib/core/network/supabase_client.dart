import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Supabase 초기화 및 전역 접근 헬퍼.
///
/// [init] 은 앱 시작 시 한 번만 호출합니다 (main.dart).
/// 이후에는 [client] 로 어디서든 접근합니다.
class SupabaseService {
  const SupabaseService._();

  /// Supabase 초기화. Env 값이 비어 있으면 조용히 건너뜁니다.
  /// (아직 백엔드 연동 전이어도 앱이 실행되도록)
  static Future<void> init() async {
    if (!Env.hasSupabase) {
      // ignore: avoid_print
      print('[SupabaseService] SUPABASE_URL/PUBLISHABLE_KEY 미설정 — 초기화 스킵');
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseKey,
    );
  }

  /// 초기화된 Supabase 클라이언트.
  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  /// 서버 API 호출에 실을 액세스 토큰. 미초기화·미로그인이면 null.
  ///
  /// [Env.hasSupabase] 를 먼저 보는 이유: 초기화를 건너뛴 상태에서
  /// [Supabase.instance] 에 접근하면 예외가 난다 (테스트·키 미설정 실행).
  static String? get currentAccessToken =>
      Env.hasSupabase ? auth.currentSession?.accessToken : null;

  /// 세션 갱신을 시도한다. 실패는 리프레시 토큰까지 죽었다는 뜻.
  static Future<bool> tryRefreshSession() async {
    if (!Env.hasSupabase) return false;
    if (auth.currentSession == null) return false;
    try {
      final response = await auth.refreshSession();
      return response.session != null;
    } on Object {
      return false;
    }
  }

  /// 세션이 있으면 끊는다. 미초기화·미로그인이면 아무것도 하지 않는다.
  static Future<void> signOutIfSignedIn() async {
    if (!Env.hasSupabase) return;
    if (auth.currentSession == null) return;
    await auth.signOut();
  }

  /// 로그인·로그아웃·토큰 갱신 스트림. 미초기화면 아무것도 흘리지 않는다.
  ///
  /// 카카오는 브라우저에서 로그인하고 딥링크로 돌아오므로, 세션이 도착하는
  /// 시점이 로그인 호출 시점과 다르다 — 상태는 반드시 이 스트림으로 받는다.
  static Stream<AuthState> get authStateChanges =>
      Env.hasSupabase ? auth.onAuthStateChange : const Stream.empty();
}
