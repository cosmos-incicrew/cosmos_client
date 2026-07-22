// 진입 흐름 분기 검증.
//
// 로그인·온보딩·게스트가 얽혀서 한 곳만 틀려도 "이미 로그인했는데 로그인 시트가
// 또 뜨거나", "온보딩을 안 했는데 홈에 들어가지는" 식으로 조용히 샌다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/router/app_router.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const signedInNoProfile = AuthState(
    status: AuthStatus.authenticated,
    provider: AuthProvider.google,
    userId: 'uuid',
  );
  const onboarded = AuthState(
    status: AuthStatus.authenticated,
    provider: AuthProvider.kakao,
    userId: 'uuid',
    onboarded: true,
  );
  const guest = AuthState(
    status: AuthStatus.guest,
    provider: AuthProvider.guest,
    userId: 'guest',
    onboarded: true,
  );

  test('세션 복원 중에는 아무 데도 보내지 않는다', () {
    // 여기서 성급히 보내면 이미 로그인한 사용자가 스플래시를 스쳐 지나간다.
    expect(redirectFor(const AuthState(), '/home'), isNull);
    expect(redirectFor(const AuthState(), '/splash'), isNull);
  });

  test('온보딩까지 마쳤으면 진입 화면을 다시 안 보여준다', () {
    expect(redirectFor(onboarded, '/splash'), '/home');
    expect(redirectFor(onboarded, '/onboarding'), '/home');
    expect(redirectFor(onboarded, '/home'), isNull);
  });

  test('로그인만 하고 프로필이 없으면 온보딩 안에 머문다', () {
    expect(redirectFor(signedInNoProfile, '/splash'), '/onboarding/profile');
    expect(redirectFor(signedInNoProfile, '/home'), '/onboarding/profile');
    // 온보딩 하위 단계끼리는 자유롭게 이동해야 한다.
    expect(redirectFor(signedInNoProfile, '/onboarding/concerns'), isNull);
  });

  test('로그인 직후 온보딩 인트로에 남지 않는다', () {
    // 로그인 시트는 인트로(/onboarding) 위에 뜬다. 여기서 로그인에 성공했는데
    // 제자리에 두면 시트만 닫히고 화면이 그대로라 "눌러도 아무 일이 없다"가 된다.
    expect(redirectFor(signedInNoProfile, '/onboarding'), '/onboarding/profile');
  });

  test('미로그인이 메인에 직접 들어오면 처음으로 되돌린다', () {
    expect(redirectFor(AuthState.unauthenticated, '/home'), '/splash');
    expect(redirectFor(AuthState.unauthenticated, '/splash'), isNull);
  });

  test('게스트는 홈에 남는다 — 로그인 요구로 막지 않는다', () {
    expect(redirectFor(guest, '/home'), isNull);
    expect(redirectFor(guest, '/shelf'), isNull);
  });
}
