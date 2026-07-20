// 로그인 화면 — SDK 연동 전에도 크래시가 아니라 안내가 떠야 한다.
//
// 목 카카오 로그인을 없앤 뒤 버튼을 누르면 UnimplementedError 가 난다.
// 그게 화면까지 올라와 앱이 죽으면 안 된다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = AuthRepository();

  test('게스트 로그인은 실제로 동작한다', () async {
    final state = await repo.signInAsGuest();
    expect(state.isSignedIn, isTrue);
  });

  test('소셜 로그인은 전부 UnimplementedError 로 통일돼 있다', () async {
    // 하나만 목으로 성공하면 "되는 줄" 알고 넘어간다 — 전부 같아야 한다.
    await expectLater(repo.signInWithKakao(), throwsUnimplementedError);
    await expectLater(repo.signInWithNaver(), throwsUnimplementedError);
    await expectLater(repo.signInWithGoogle(), throwsUnimplementedError);
    await expectLater(repo.signInWithApple(), throwsUnimplementedError);
  });
}
