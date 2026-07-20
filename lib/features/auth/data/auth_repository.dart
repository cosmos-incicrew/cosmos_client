import '../../../core/mock/mock_data.dart';
import 'auth_state.dart';

/// 인증 저장소 인터페이스.
///
/// 지금은 게스트 로그인만 실제 동작합니다.
/// 소셜 로그인은 각 SDK 연동 후 아래 TODO 자리를 채우면 됩니다.
class AuthRepository {
  const AuthRepository();

  /// 게스트(익명) 로그인.
  ///
  /// Supabase 익명 로그인을 쓸 경우:
  ///   final res = await SupabaseService.auth.signInAnonymously();
  /// 지금은 백엔드 없이도 동작하도록 로컬 게스트 세션만 생성합니다.
  Future<AuthState> signInAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const AuthState(
      status: AuthStatus.guest,
      provider: AuthProvider.guest,
      userId: 'guest',
      displayName: '게스트',
    );
  }

  /// 카카오 로그인.
  ///
  /// ⚠️ 지금은 **목 로그인** — SDK 없이 누르면 무조건 성공한다.
  /// (mockKakaoUser 반환. lib/core/mock/ 참고)
  ///
  /// TODO: kakao_flutter_sdk_user 연동 시 아래 목 반환을 지우고 실제 구현으로 교체
  ///   1) main 에서 KakaoSdk.init(nativeAppKey: ...)
  ///   2) UserApi.instance.loginWithKakaoTalk() / loginWithKakaoAccount()
  ///   3) 받은 토큰으로 Supabase signInWithIdToken 연동
  Future<AuthState> signInWithKakao() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return mockKakaoUser;
  }

  /// 네이버 로그인 (커뮤니티 SDK — 초기 PoC)
  Future<AuthState> signInWithNaver() async {
    throw UnimplementedError('네이버 로그인 미구현');
  }

  /// 구글 로그인
  Future<AuthState> signInWithGoogle() async {
    throw UnimplementedError('구글 로그인 미구현');
  }

  /// 애플 로그인
  Future<AuthState> signInWithApple() async {
    throw UnimplementedError('애플 로그인 미구현');
  }

  Future<void> signOut() async {
    // TODO: Supabase / 각 SDK 로그아웃 호출
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  /// 앱 시작 시 기존 세션 복원.
  /// TODO: SupabaseService.auth.currentSession 확인
  Future<AuthState> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return AuthState.unauthenticated;
  }
}
