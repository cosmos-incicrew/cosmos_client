// 프로필 등록 화면 검증 — 폰 크기에서 안 깨지고, 성별에 따라 임신·수유가 뜨는지.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/theme/app_theme.dart';
import 'package:cosmos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmos_app/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  /// ⚠️ 실제 앱(app_router)과 같은 리다이렉트 규칙을 넣는다.
  /// 이게 없으면 "온보딩 안 끝났는데 /bsti 가면 스플래시로 튕기는" 버그를
  /// 테스트가 못 잡는다. (실제로 한 번 놓쳤다)
  Widget app(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/onboarding/profile',
      redirect: (context, state) {
        final auth = container.read(authControllerProvider);
        final loc = state.matchedLocation;
        final inEntryFlow = loc == '/splash' || loc.startsWith('/onboarding');
        if (!auth.onboarded && !inEntryFlow) return '/splash';
        return null;
      },
      routes: [
        GoRoute(
            path: '/onboarding/profile',
            builder: (_, __) => const ProfileSetupScreen()),
        GoRoute(path: '/splash', builder: (_, __) => const Text('오프닝화면')),
        GoRoute(path: '/bsti', builder: (_, __) => const Text('BSTI화면')),
        GoRoute(path: '/home', builder: (_, __) => const Text('홈화면')),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(app(container));
    // AuthController 가 시작 시 restoreSession(200ms 목 지연)을 건다.
    // 그냥 두면 위젯 트리가 사라진 뒤 타이머가 남아 !timersPending 로 터진다.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('폰 크기에서 오버플로우 없이 렌더된다', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('피부고민 8개가 한글 라벨로 보인다 (코드는 안 보임)', (tester) async {
    await pump(tester);

    expect(find.text('모공'), findsOneWidget);
    expect(find.text('미백'), findsOneWidget);
    expect(find.text('주름'), findsOneWidget);
    expect(find.text('민감성'), findsOneWidget);
    // 코드가 화면에 새어나오면 안 된다.
    expect(find.text('pores'), findsNothing);
    expect(find.text('brightening'), findsNothing);
  });

  testWidgets('여성을 고르면 임신·수유가 뜨고, 남성을 고르면 사라진다', (tester) async {
    await pump(tester);

    // 처음엔 안 보인다.
    expect(find.text('임신 및 수유 여부'), findsNothing);

    await tester.tap(find.text('여성'));
    await tester.pumpAndSettle();
    expect(find.text('임신 및 수유 여부'), findsOneWidget);
    expect(find.text('임신 중'), findsOneWidget);

    await tester.tap(find.text('남성'));
    await tester.pumpAndSettle();
    expect(find.text('임신 및 수유 여부'), findsNothing);
  });

  // 실제 앱에서 오프닝으로 튕기던 버그를 잡는 테스트.
  testWidgets('BSTI TEST 를 누르면 오프닝이 아니라 BSTI 로 간다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('BSTI TEST'));
    await tester.pumpAndSettle();

    expect(find.text('BSTI화면'), findsOneWidget);
    expect(find.text('오프닝화면'), findsNothing);
  });

  testWidgets('HOME 을 누르면 팝업이 뜨고, 계속하기면 안 나간다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    expect(find.textContaining('맞춤형 화장품 추천이 가능합니다'), findsOneWidget);

    await tester.tap(find.text('계속하기'));
    await tester.pumpAndSettle();
    // 프로필에 그대로 남아야 한다.
    expect(find.text('홈화면'), findsNothing);
    expect(find.text('피부고민'), findsOneWidget);
  });

  testWidgets('HOME → 홈으로 누르면 오프닝이 아니라 홈으로 간다', (tester) async {
    await pump(tester);

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈으로'));
    await tester.pumpAndSettle();

    expect(find.text('홈화면'), findsOneWidget);
    expect(find.text('오프닝화면'), findsNothing);
  });
}
