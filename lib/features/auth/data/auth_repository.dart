import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import '../../../core/network/supabase_client.dart';
import 'auth_state.dart';

/// 인증 저장소.
///
/// 카카오·구글은 **Supabase OAuth** 로 로그인한다 — 백엔드(cosmos_server)에는
/// 로그인 엔드포인트가 없고, Supabase 가 발급한 JWT 를 검증만 한다
/// (서버 `app/core/auth.py`). OAuth 제공자 설정은 공유 Supabase 프로젝트에
/// 되어 있으므로, 앱은 SUPABASE_URL/ANON_KEY 만 있으면 된다.
///
/// 네이버는 실제 연동 계획이 없어 **목업**(누르면 성공)으로 둔다.
class AuthRepository {
  const AuthRepository();

  /// 게스트(익명) 로그인. 백엔드 없이도 동작하는 로컬 세션.
  Future<AuthState> signInAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthState(
      status: AuthStatus.guest,
      provider: AuthProvider.guest,
      userId: 'guest',
      displayName: '게스트',
    );
  }

  /// 카카오 로그인 — Supabase OAuth.
  ///
  /// 웹에서는 카카오 동의 화면으로 리다이렉트됐다가 앱으로 돌아온다.
  /// 돌아오면 앱이 다시 시작되고 [restoreSession] 이 세션을 읽는다.
  /// (그래서 이 메서드는 리다이렉트를 "시작"만 하고 상태를 돌려주지 않는다)
  ///
  /// SUPABASE_URL/ANON_KEY 가 없으면 UnimplementedError —
  /// 로그인 화면이 "준비 중" 안내로 처리한다.
  Future<void> signInWithKakao() async {
    if (!Env.hasSupabase) {
      throw UnimplementedError('Supabase 미설정 — 카카오 로그인 불가');
    }
    await SupabaseService.auth.signInWithOAuth(sb.OAuthProvider.kakao);
  }

  /// 구글 로그인 — Supabase OAuth. 흐름은 [signInWithKakao] 와 동일.
  Future<void> signInWithGoogle() async {
    if (!Env.hasSupabase) {
      throw UnimplementedError('Supabase 미설정 — 구글 로그인 불가');
    }
    await SupabaseService.auth.signInWithOAuth(sb.OAuthProvider.google);
  }

  /// 네이버 로그인 — ⚠️ 목업. 실제 연동 계획이 없어 누르면 성공한다.
  /// (네이버는 Supabase 기본 제공자가 아니라 붙이려면 커스텀 OIDC 가 필요)
  Future<AuthState> signInWithNaver() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthState(
      status: AuthStatus.authenticated,
      provider: AuthProvider.naver,
      userId: 'mock_naver_1',
      displayName: '네이버 테스트 유저',
    );
  }

  /// 애플 로그인 — 미구현.
  Future<AuthState> signInWithApple() async {
    throw UnimplementedError('애플 로그인 미구현');
  }

  Future<void> signOut() async {
    if (Env.hasSupabase && SupabaseService.auth.currentSession != null) {
      await SupabaseService.auth.signOut();
    }
  }

  /// 앱 시작 시 기존 세션 복원.
  ///
  /// OAuth 리다이렉트에서 돌아온 직후도 이 경로다 —
  /// supabase_flutter 가 URL 의 토큰을 처리해 세션을 만들어둔다.
  Future<AuthState> restoreSession() async {
    if (!Env.hasSupabase) return AuthState.unauthenticated;

    final session = SupabaseService.auth.currentSession;
    final user = session?.user;
    if (user == null) return AuthState.unauthenticated;

    return AuthState(
      status: AuthStatus.authenticated,
      provider: _providerOf(user),
      userId: user.id,
      displayName: (user.userMetadata?['name'] ??
          user.userMetadata?['full_name'] ??
          user.email) as String?,
    );
  }

  /// Supabase 유저의 로그인 제공자 → 앱 enum.
  static AuthProvider _providerOf(sb.User user) {
    switch (user.appMetadata['provider']) {
      case 'kakao':
        return AuthProvider.kakao;
      case 'google':
        return AuthProvider.google;
      default:
        return AuthProvider.none;
    }
  }
}
