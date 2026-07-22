import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../data/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// 앱 전역 인증 상태를 관리하는 Notifier.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    state = await _repo.restoreSession();
  }

  Future<void> signInAsGuest() async {
    state = await _repo.signInAsGuest();
  }

  /// 카카오 로그인 — Supabase OAuth 리다이렉트를 시작한다.
  ///
  /// 리다이렉트에서 돌아오면 앱이 재시작되고 [_restore] 가 세션을 읽으므로
  /// 여기서 상태를 바꾸지 않는다. Supabase 미설정이면 [UnimplementedError] 가
  /// 그대로 올라가 화면이 "준비 중" 안내를 띄운다.
  Future<void> signInWithKakao() => _repo.signInWithKakao();

  /// 구글 로그인 — 흐름은 카카오와 동일.
  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  /// 네이버 로그인 — ⚠️ 목업 (실제 연동 계획 없음).
  Future<void> signInWithNaver() async {
    state = await _repo.signInWithNaver();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = AuthState.unauthenticated;
  }

  /// 온보딩(프로필·피부고민)을 마쳤을 때 호출 → 홈으로 진입 가능.
  void completeOnboarding() {
    state = state.copyWith(onboarded: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
