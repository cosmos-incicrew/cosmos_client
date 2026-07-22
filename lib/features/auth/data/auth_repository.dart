import 'dart:async';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import '../../../core/network/supabase_client.dart';
import 'auth_state.dart';

/// 카카오 로그인은 브라우저를 거쳐 딥링크로 돌아온다 — 그 사이 사용자가 화면을
/// 떠나거나 취소하면 세션이 영영 안 오므로, 무한 대기 대신 끊는다.
const _kakaoSignInTimeout = Duration(minutes: 3);

/// 인증 저장소.
///
/// 로그인 자체는 Supabase Auth 가 한다. 서버(cosmos_server)에는 로그인
/// 엔드포인트가 없고, 여기서 받은 JWT 를 Bearer 로 실어 보낼 뿐이다.
///
/// 게스트는 Supabase 세션이 없다 — 서버 API(맞춤 추천 등)를 못 쓰고
/// 로컬 기능만 쓰는 상태로 남는다.
class AuthRepository {
  const AuthRepository();

  /// 게스트(익명) 로그인 — 로컬 세션만 만든다. 서버 API 는 쓸 수 없다.
  ///
  /// onboarded 를 함께 세워 한 번에 발행한다. 나눠 발행하면 그 사이 라우터가
  /// `/onboarding/profile` 로 한 번 튕겼다 돌아온다.
  Future<AuthState> signInAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthState(
      status: AuthStatus.guest,
      provider: AuthProvider.guest,
      userId: 'guest',
      displayName: '게스트',
      onboarded: true,
    );
  }

  /// 구글 로그인 — 네이티브 SDK 로 ID 토큰을 받아 Supabase 에 넘긴다.
  ///
  /// 웹 OAuth 가 아니라 네이티브인 이유: 구글이 인앱 웹뷰 로그인을 막아서,
  /// 안드로이드에서는 네이티브 흐름이 더 짧고 안정적이다.
  Future<AuthState> signInWithGoogle() async {
    if (!Env.hasGoogleSignIn) {
      throw const AuthNotConfiguredException('구글 로그인 설정이 아직 없습니다.');
    }
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(serverClientId: Env.googleWebClientId);

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await googleSignIn.authenticate();
    } on GoogleSignInException catch (error) {
      // canceled 만 조용히 넘긴다. 나머지는 원문을 올려 화면이 안내하게 둔다.
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCancelledException();
      }
      rethrow;
    }
    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const sb.AuthException('구글 ID 토큰을 받지 못했습니다.');
    }
    // accessToken 은 넘기지 않는다 — Supabase 인증에는 ID 토큰이면 충분하고,
    // 스코프 authorization 을 따로 받으면 안드로이드에서 동의 창이 한 번 더 뜬다.
    // 구글 API 를 직접 호출할 일이 생기면 그때 authorizationClient 를 쓴다.
    final response = await SupabaseService.auth.signInWithIdToken(
      provider: sb.OAuthProvider.google,
      idToken: idToken,
    );
    return stateFromSession(response.session);
  }

  /// 카카오 로그인 — Supabase 웹 OAuth. 브라우저에서 로그인하고 딥링크로 돌아온다.
  ///
  /// [sb.GoTrueClient.signInWithOAuth] 는 브라우저를 띄우면 바로 반환하므로
  /// 세션은 그 뒤에 스트림으로 도착한다. 호출한 화면이 로그인 전에 넘어가버리지
  /// 않도록 여기서 기다렸다가 결과를 돌려준다.
  Future<AuthState> signInWithKakao() async {
    if (!Env.hasSupabase) {
      throw const AuthNotConfiguredException('Supabase 설정이 아직 없습니다.');
    }
    // onAuthStateChange 는 BehaviorSubject 라 구독하는 순간 마지막 이벤트를 재생한다.
    // `session != null` 만 보면 이전 로그인 세션이나 토큰 갱신이 곧바로 걸려서,
    // 브라우저가 뜨기도 전에 "로그인 성공"으로 끝나버린다. 그래서 두 겹으로 거른다.
    //  - signedIn 이벤트만 (tokenRefreshed·initialSession 배제)
    //  - 직전 토큰과 다른 세션만 (재생된 과거 이벤트 배제)
    final previousToken = SupabaseService.auth.currentSession?.accessToken;
    final signedIn = Completer<sb.Session>();
    // 브라우저를 띄우기 전에 구독한다 — 뒤에 걸면 빠른 복귀를 놓칠 수 있다.
    final subscription = SupabaseService.authStateChanges.listen((event) {
      final session = event.session;
      if (event.event != sb.AuthChangeEvent.signedIn) return;
      if (session == null || session.accessToken == previousToken) return;
      if (!signedIn.isCompleted) signedIn.complete(session);
    });

    try {
      await SupabaseService.auth.signInWithOAuth(
        sb.OAuthProvider.kakao,
        redirectTo: Env.authRedirectUrl,
        // 인앱 웹뷰 대신 외부 브라우저 — 카카오톡 앱 전환 로그인을 쓰려면 필요하다.
        authScreenLaunchMode: sb.LaunchMode.externalApplication,
        // Supabase 는 카카오에 account_email 을 기본으로 요구하는데, 이 항목은
        // 비즈 앱만 설정할 수 있다. 일반 앱에서는 카카오가 invalid_scope 로 끊는다.
        // 이름 있는 인자 scopes 는 기본 목록에 '덧붙기만' 해서 소용없고,
        // 쿼리 파라미터 scope(단수) 를 실어야 목록이 통째로 교체된다.
        queryParams: const {'scope': 'profile_nickname profile_image'},
      );
      return stateFromSession(
        await signedIn.future.timeout(_kakaoSignInTimeout),
      );
    } finally {
      // 성공·실패·타임아웃 어느 경로로 나가든 구독을 끊는다.
      // (Future.timeout 은 원본을 취소하지 못해, 안 끊으면 시도마다 하나씩 쌓인다)
      await subscription.cancel();
    }
  }

  /// 네이버 로그인 — ⚠️ 목업 (실제 연동 계획 없음, 누르면 성공).
  ///
  /// 네이버는 Supabase 기본 제공자가 아니라 붙이려면 커스텀 OIDC 가 필요한데,
  /// v1 에서는 하지 않기로 했다. 게스트처럼 Supabase 세션이 없으므로
  /// 서버 API(맞춤 추천 등)는 쓰지 못한다.
  Future<AuthState> signInWithNaver() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthState(
      status: AuthStatus.authenticated,
      provider: AuthProvider.naver,
      userId: 'mock_naver_1',
      displayName: '네이버 테스트 유저',
    );
  }

  /// 애플 로그인 — v1 제외 (안드로이드 전용 앱).
  Future<AuthState> signInWithApple() async {
    throw UnimplementedError('애플 로그인 미구현');
  }

  Future<void> signOut() async {
    if (!Env.hasSupabase) return;
    await SupabaseService.auth.signOut();
  }

  /// 앱 시작 시 기존 세션 복원. 없으면 미인증.
  Future<AuthState> restoreSession() async {
    if (!Env.hasSupabase) return AuthState.unauthenticated;
    return stateFromSession(SupabaseService.auth.currentSession);
  }

  /// Supabase 세션 → 앱 인증 상태.
  ///
  /// 온보딩 완료 여부는 서버 프로필을 봐야 알 수 있어 여기서 채우지 않는다
  /// (AuthController 가 조회해 덧붙인다).
  static AuthState stateFromSession(sb.Session? session) {
    final user = session?.user;
    if (user == null) return AuthState.unauthenticated;
    return AuthState(
      status: AuthStatus.authenticated,
      provider: _providerOf(user),
      userId: user.id,
      displayName: _displayNameOf(user),
    );
  }

  static AuthProvider _providerOf(sb.User user) {
    switch (user.appMetadata['provider']) {
      case 'google':
        return AuthProvider.google;
      case 'kakao':
        return AuthProvider.kakao;
      default:
        return AuthProvider.none;
    }
  }

  /// 소셜에서 받은 표시 이름. 카카오는 비즈 앱 전환 전이면 이메일도 안 주므로
  /// 없으면 null 로 둔다 — 닉네임은 온보딩에서 직접 받는다.
  static String? _displayNameOf(sb.User user) {
    final metadata = user.userMetadata;
    for (final key in ['name', 'full_name', 'nickname']) {
      final value = metadata?[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}

/// 사용자가 로그인 창을 스스로 닫았다. 실패가 아니므로 화면은 안내를 띄우지 않는다.
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => '사용자가 로그인을 취소했습니다.';
}

/// 소셜 로그인 키가 아직 안 채워진 상태. 화면은 "준비 중" 안내를 띄운다.
class AuthNotConfiguredException implements Exception {
  const AuthNotConfiguredException(this.message);

  final String message;

  @override
  String toString() => message;
}
