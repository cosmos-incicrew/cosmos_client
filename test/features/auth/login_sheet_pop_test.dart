// 로그인 시트가 "자기 route 만" 닫는지 검증.
//
// 로그인은 브라우저 왕복이라 오래 걸리고, 그 사이 화면 스택이 바뀐다. 무턱대고
// pop 하면 남의 route 를 닫는다 — 실기기에서 go_router 크래시로 터졌던 지점이다.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';

import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:cosmos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmos_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 카카오 로그인이 끝나는 시점을 테스트가 직접 잡는 대역.
class _PendingKakaoRepository extends AuthRepository {
  const _PendingKakaoRepository(this.gate);

  final Completer<void> gate;

  @override
  Future<AuthState> signInWithKakao() async {
    await gate.future;
    return const AuthState(
      status: AuthStatus.authenticated,
      provider: AuthProvider.kakao,
      userId: 'uuid',
    );
  }
}

Widget _app(GlobalKey<NavigatorState> navigatorKey, Completer<void> gate) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_PendingKakaoRepository(gate)),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: const Scaffold(body: Center(child: Text('아래 페이지'))),
    ),
  );
}

/// 카카오 아이콘 = 소셜 Row 의 첫 InkWell.
Finder get _kakaoButton => find.byType(InkWell).first;

void main() {
  testWidgets('로그인 중에 다른 화면이 위로 올라오면 그 화면을 닫지 않는다', (tester) async {
    final gate = Completer<void>();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigatorKey, gate));

    unawaited(LoginSheet.show(navigatorKey.currentContext!));
    await tester.pumpAndSettle();

    await tester.tap(_kakaoButton);
    await tester.pump();

    // 실기기에서는 인증 상태 변화가 라우터를 움직여 같은 상황이 만들어졌다.
    unawaited(navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: Text('위 페이지'))),
      ),
    ));
    await tester.pumpAndSettle();

    // 이제 로그인이 성공한다 — 시트는 살아 있지만 최상단이 아니다.
    gate.complete();
    await tester.pumpAndSettle();

    // 가드가 없으면 여기서 '위 페이지' 가 대신 닫힌다.
    expect(find.text('위 페이지'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시트가 최상단이면 로그인 성공 후 스스로 닫힌다', (tester) async {
    final gate = Completer<void>();
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(_app(navigatorKey, gate));

    unawaited(LoginSheet.show(navigatorKey.currentContext!));
    await tester.pumpAndSettle();
    expect(find.text('또는'), findsOneWidget);

    await tester.tap(_kakaoButton);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();

    // 시트만 닫히고 아래 페이지는 남는다.
    expect(find.text('또는'), findsNothing);
    expect(find.text('아래 페이지'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
