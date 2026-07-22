// 설문을 마치면 BSTI 결과가 실제로 저장되는지 검증.
// 보고서가 이 값을 읽으므로, 여기가 비면 보고서가 빈 화면이 된다.
//
// 결과의 단일 소스는 UserProfile.bstiType 이다 — bstiResultProvider 는 거기서
// 파생된 읽기 전용 값이라, 저장은 userProfileProvider 를 통한다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/bsti/bsti_result_store.dart';
import 'package:cosmos_app/features/bsti/bsti_test_screen.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../support/fake_repositories.dart';

void main() {
  test('저장/삭제가 동작한다', () async {
    final c = ProviderContainer(overrides: fakeRepos);
    addTearDown(c.dispose);

    expect(c.read(bstiResultProvider), isNull);

    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    expect(c.read(bstiResultProvider), 'OSPW');

    // 로그아웃 등으로 프로필을 비우면 BSTI 도 같이 사라져야 한다.
    c.read(userProfileProvider.notifier).clear();
    expect(c.read(bstiResultProvider), isNull);
  });

  test('프로필을 저장해도 BSTI 결과는 남는다', () async {
    // 마이페이지에서 닉네임만 고쳤다고 검사 결과가 지워지면 안 된다.
    final c = ProviderContainer(overrides: fakeRepos);
    addTearDown(c.dispose);

    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    await c.read(userProfileProvider.notifier)
        .save(const UserProfile(nickname: '민경', age: 28));

    expect(c.read(bstiResultProvider), 'OSPW');
    expect(c.read(userProfileProvider).nickname, '민경');
  });

  testWidgets('설문을 끝까지 풀면 결과가 저장된다', (tester) async {
    final container = ProviderContainer(overrides: fakeRepos);
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/bsti/test',
      routes: [
        GoRoute(path: '/bsti/test', builder: (_, __) => const BstiTestScreen()),
        GoRoute(
          path: '/bsti/result',
          builder: (_, state) =>
              Scaffold(body: Text('RESULT:${state.uri.queryParameters['code']}')),
        ),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    // 검사 전에는 비어 있다.
    expect(container.read(bstiResultProvider), isNull);

    // 모든 문항에 첫 보기를 골라 끝까지 진행한다.
    for (var i = 0; i < kBstiQuestions.length; i++) {
      final q = kBstiQuestions[i];
      await tester.tap(find.text(q.options.first.label).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == kBstiQuestions.length - 1 ? '결과 보기' : '다음'));
      await tester.pumpAndSettle();
    }

    // 결과 화면으로 넘어갔고, 저장도 됐어야 한다.
    final saved = container.read(bstiResultProvider);
    expect(saved, isNotNull);
    expect(saved, hasLength(4)); // 예: OSPW
    expect(find.text('RESULT:$saved'), findsOneWidget);
  });
}
