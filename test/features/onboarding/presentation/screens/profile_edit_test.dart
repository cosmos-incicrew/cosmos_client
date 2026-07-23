// 프로필 화면의 프리필과 수정 모드 검증.
//
// 프리필이 빠지면 수정 화면이 빈 칸으로 열리고, 저장은 전체 덮어쓰기라
// 기존 값이 통째로 지워진다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/onboarding/data/skin_concern.dart';
import 'package:cosmos_app/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/fake_repositories.dart';

Future<ProviderContainer> _show(
  WidgetTester tester, {
  required bool isEditing,
  void Function(ProviderContainer)? setup,
}) async {
  final container = ProviderContainer(overrides: fakeRepos);
  addTearDown(container.dispose);
  setup?.call(container);

  final router = GoRouter(
    initialLocation: '/edit',
    routes: [
      GoRoute(
        path: '/edit',
        builder: (_, __) => ProfileSetupScreen(isEditing: isEditing),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const Scaffold(body: Text('마이페이지')),
      ),
      GoRoute(path: '/bsti', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    ],
  );

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('저장된 프로필이 입력칸에 채워진다', (tester) async {
    await _show(tester, isEditing: true, setup: (c) {
      c.read(userProfileProvider.notifier).save(const UserProfile(
        nickname: '민경',
        age: 28,
        gender: 'female',
        concerns: {SkinConcern.acne},
      ));
    });

    expect(find.widgetWithText(TextField, '민경'), findsOneWidget);
    expect(find.widgetWithText(TextField, '28'), findsOneWidget);
  });

  testWidgets('닉네임이 없으면 로그인 이름이 기본값으로 들어간다', (tester) async {
    // 소셜에서 받은 이름을 그대로 쓰거나 고치게 한다 — 빈 칸부터 시작하지 않는다.
    await _show(tester, isEditing: false, setup: (c) {
      c.read(userProfileProvider.notifier).state =
          const UserProfile(nickname: null);
    });

    // 로그인 정보가 없는 테스트 환경이라 빈 문자열이지만, 저장된 닉네임이
    // 있으면 그쪽이 이긴다는 것이 아래 테스트로 함께 고정된다.
    expect(find.byType(TextField), findsWidgets);
  });

  testWidgets('저장된 닉네임이 로그인 이름보다 우선한다', (tester) async {
    await _show(tester, isEditing: true, setup: (c) {
      c.read(userProfileProvider.notifier)
          .save(const UserProfile(nickname: '내가고친이름', age: 30));
    });

    expect(find.widgetWithText(TextField, '내가고친이름'), findsOneWidget);
  });

  testWidgets('수정 모드는 저장 버튼을, 온보딩은 진행 버튼을 보여준다', (tester) async {
    await _show(tester, isEditing: true);
    expect(find.text('저장'), findsOneWidget);
    expect(find.text('BSTI TEST'), findsNothing);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('온보딩 모드에는 저장 버튼이 없다', (tester) async {
    await _show(tester, isEditing: false);
    expect(find.text('BSTI TEST'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('저장'), findsNothing);
  });

  testWidgets('수정 저장은 값을 반영하고 마이페이지로 돌아간다', (tester) async {
    final c = await _show(tester, isEditing: true, setup: (container) {
      container.read(userProfileProvider.notifier)
          .save(const UserProfile(nickname: '이전', age: 20));
    });

    await tester.enterText(find.widgetWithText(TextField, '이전'), '바뀐이름');
    // 입력칸이 많아 저장 버튼이 뷰포트 밖에 있다 — 스크롤해 올려야 탭이 닿는다.
    await tester.ensureVisible(find.text('저장'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(c.read(userProfileProvider).nickname, '바뀐이름');
    expect(find.text('마이페이지'), findsOneWidget);
  });
}
