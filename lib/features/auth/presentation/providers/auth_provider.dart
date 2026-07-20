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

  /// 카카오 로그인.
  ///
  /// 아직 SDK 연동 전이라 [UnimplementedError] 가 난다.
  /// 상태를 건드리지 않고 그대로 올려보내, 화면이 안내 문구를 띄우게 한다.
  /// (여기서 삼키면 버튼을 눌러도 아무 일도 안 일어난 것처럼 보인다)
  Future<void> signInWithKakao() async {
    state = await _repo.signInWithKakao();
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
