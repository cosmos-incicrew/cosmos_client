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
      print('[SupabaseService] SUPABASE_URL/ANON_KEY 미설정 — 초기화 스킵');
      return;
    }
    await Supabase.initialize(
      url: Env.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: Env.supabaseAnonKey,
    );
  }

  /// 초기화된 Supabase 클라이언트.
  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;
}
