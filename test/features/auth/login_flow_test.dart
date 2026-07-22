// 로그인 동작 검증.
//
// - 게스트: 실제 동작 (로컬 세션)
// - 네이버: ⚠️ 의도된 목업 (실제 연동 계획 없음 — 누르면 성공)
// - 카카오·구글: Supabase OAuth. 테스트 환경엔 SUPABASE_URL 이 없으므로
//   UnimplementedError 가 나야 한다 (화면은 "준비 중" 안내로 처리).
// - 애플: 미구현
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

  test('네이버는 목업 — 누르면 성공한다', () async {
    final state = await repo.signInWithNaver();
    expect(state.status, AuthStatus.authenticated);
    expect(state.provider, AuthProvider.naver);
  });

  test('카카오·구글은 Supabase 미설정 시 UnimplementedError', () async {
    // 크래시가 아니라 화면에서 잡아 "준비 중" 안내로 이어진다.
    await expectLater(repo.signInWithKakao(), throwsUnimplementedError);
    await expectLater(repo.signInWithGoogle(), throwsUnimplementedError);
  });

  test('애플은 미구현', () async {
    await expectLater(repo.signInWithApple(), throwsUnimplementedError);
  });

  test('세션 없으면 미로그인으로 복원된다', () async {
    // Supabase 미설정 → 항상 unauthenticated (크래시 아님).
    final state = await repo.restoreSession();
    expect(state.status, AuthStatus.unauthenticated);
  });
}
