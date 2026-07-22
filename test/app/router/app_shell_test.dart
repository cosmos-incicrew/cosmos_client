// 하단 탭 순서 검증.
//
// destinations(app_shell) 순서와 branches(app_router) 순서는 인덱스로 짝을 이룬다.
// 한쪽만 바꾸면 "화장대를 눌렀는데 홈이 뜨는" 식으로 조용히 어긋나므로 고정해둔다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/router/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  /// 탭 쉘만 띄우는 미니 라우터 — 실제 화면 대신 이름표만 둔다.
  Widget app() {
    final router = GoRouter(
      initialLocation: '/shelf',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(routes: [
              GoRoute(path: '/shelf', builder: (_, __) => const Text('화장대화면')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/home', builder: (_, __) => const Text('홈화면')),
            ]),
            StatefulShellBranch(routes: [
              GoRoute(path: '/profile', builder: (_, __) => const Text('마이화면')),
            ]),
          ],
        ),
      ],
    );
    return MaterialApp.router(routerConfig: router);
  }

  testWidgets('하단 탭은 화장대 → 홈 → 마이 순서다', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label)
        .toList();

    expect(labels, ['SHELF', 'HOME', 'MY']);
  });

  testWidgets('홈 탭을 누르면 홈이 뜬다 (인덱스 정합성)', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();

    expect(find.text('홈화면'), findsOneWidget);
  });
}
