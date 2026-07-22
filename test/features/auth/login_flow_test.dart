// 로그인 화면 — 키가 안 채워진 상태에서도 크래시가 아니라 안내가 떠야 한다.
//
// Supabase URL/anon key 나 구글 클라이언트 ID 가 비어 있으면 로그인은 못 하지만,
// 그게 예외로 화면까지 올라와 앱이 죽으면 안 된다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = AuthRepository();

  test('게스트 로그인은 실제로 동작한다', () async {
    final state = await repo.signInAsGuest();
    expect(state.isSignedIn, isTrue);
  });

  test('게스트는 서버 세션이 없어 맞춤 추천을 못 쓴다', () async {
    final state = await repo.signInAsGuest();
    // userId 가 Supabase uuid 가 아니라는 것 = 서버에 보낼 토큰이 없다는 뜻.
    expect(state.status, AuthStatus.guest);
    expect(state.userId, 'guest');
  });

  test('설정 전에는 구글·카카오가 안내용 예외를 던진다', () async {
    // 설정 누락과 진짜 로그인 실패를 구분해야 화면이 맞는 안내를 띄운다.
    await expectLater(
      repo.signInWithGoogle(),
      throwsA(isA<AuthNotConfiguredException>()),
    );
    await expectLater(
      repo.signInWithKakao(),
      throwsA(isA<AuthNotConfiguredException>()),
    );
  });

  test('애플은 v1 제외라 미구현으로 남는다', () async {
    await expectLater(repo.signInWithApple(), throwsUnimplementedError);
  });
}
