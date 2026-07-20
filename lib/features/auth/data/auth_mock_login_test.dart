// 카카오 목 로그인 검증 — SDK 없이 무조건 성공해야 한다.
// (실제 SDK 연동 시 이 테스트도 함께 교체)
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = AuthRepository();

  test('카카오 로그인은 목으로 무조건 성공한다', () async {
    final state = await repo.signInWithKakao();

    expect(state.status, AuthStatus.authenticated);
    expect(state.provider, AuthProvider.kakao);
    expect(state.isSignedIn, isTrue);
    expect(state.displayName, isNotNull);
  });

  test('게스트 로그인도 여전히 동작한다', () async {
    final state = await repo.signInAsGuest();

    expect(state.status, AuthStatus.guest);
    expect(state.isSignedIn, isTrue);
  });

  test('아직 목이 없는 소셜은 UnimplementedError', () async {
    expect(() => repo.signInWithNaver(), throwsUnimplementedError);
    expect(() => repo.signInWithGoogle(), throwsUnimplementedError);
  });
}
