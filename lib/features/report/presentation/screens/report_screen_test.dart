// 보고서 화면 검증 — BSTI 유형 × 담은 제품 → 점수·근거 표시.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/theme/app_theme.dart';
import 'package:cosmos_app/features/bsti/bsti_result_store.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/presentation/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/report',
      routes: [
        GoRoute(path: '/report', builder: (_, __) => const ReportScreen()),
        GoRoute(path: '/home', builder: (_, __) => const Text('홈화면')),
        GoRoute(path: '/shelf/add', builder: (_, __) => const Text('검색화면')),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('BSTI 검사 전에는 검사 안내가 뜬다', (tester) async {
    await pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.textContaining('BSTI 검사'), findsWidgets);
  });

  testWidgets('검사 후 제품이 없으면 담기 안내가 뜬다', (tester) async {
    final c = await pump(tester);

    c.read(bstiResultProvider.notifier).save('OSPW');
    await tester.pumpAndSettle();

    expect(find.text('OSPW'), findsOneWidget);
    expect(find.textContaining('담은 제품이 없어요'), findsOneWidget);
  });

  testWidgets('검사 + 제품 담으면 점수와 근거가 보인다', (tester) async {
    final c = await pump(tester);

    c.read(bstiResultProvider.notifier).save('OSPW');
    // 목데이터 1번 제품 (아토베리어365 하이드로 에센스)
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 1,
          name: '아토베리어365 하이드로 에센스',
          isProduct: true,
          kind: PreferenceKind.like,
        ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('아토베리어365 하이드로 에센스'), findsOneWidget);
    // 점수 근거(권장/주의 개수)가 함께 보여야 한다.
    expect(find.textContaining('권장 '), findsWidgets);
    expect(find.textContaining('주의 '), findsWidgets);
  });

  testWidgets('담은 성분은 제품 목록에 안 나온다', (tester) async {
    final c = await pump(tester);

    c.read(bstiResultProvider.notifier).save('OSPW');
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 103,
          name: '글리세린',
          isProduct: false,
          kind: PreferenceKind.like,
        ));
    await tester.pumpAndSettle();

    expect(find.text('글리세린'), findsNothing);
    expect(find.textContaining('담은 제품이 없어요'), findsOneWidget);
  });
}
