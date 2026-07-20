// 검색에서 담으면 화장대에 실제로 남는지 검증.
//
// "담았는데 화장대가 비어있다"는 신고를 재현/방지한다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/my_shelf_screen.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/shelf_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<ProviderContainer> pump(WidgetTester tester, String start) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(path: '/shelf', builder: (_, __) => const MyShelfScreen()),
        GoRoute(path: '/shelf/add', builder: (_, __) => const ShelfAddScreen()),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('검색 화면에서 담은 성분이 화장대에 남는다', (tester) async {
    final c = await pump(tester, '/shelf/add');

    // 성분 검색 → 팝업 → 선호로 담기
    await tester.enterText(find.byType(TextField), '글리세린');
    await tester.pumpAndSettle();

    // + 버튼 (담기)
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('선호 성분으로 추가'));
    await tester.pumpAndSettle();

    // 저장됐는지 확인
    final saved = c.read(shelfPreferenceProvider);
    expect(saved, hasLength(1), reason: '담았는데 저장이 안 되면 화장대가 빈다');
    expect(saved.single.isProduct, isFalse);
    expect(saved.single.kind, PreferenceKind.like);
  });

  testWidgets('화장대 화면이 담은 성분을 보여준다', (tester) async {
    final c = await pump(tester, '/shelf');

    // 처음엔 비어 있다.
    expect(find.text('아직 담은 성분이 없어요'), findsOneWidget);

    // 담으면
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 103,
          name: '글리세린',
          isProduct: false,
          kind: PreferenceKind.like,
        ));
    await tester.pumpAndSettle();

    // 내 성분 목록에 뜬다.
    expect(find.text('글리세린'), findsOneWidget);
    expect(find.text('선호 성분'), findsOneWidget);
    expect(find.text('아직 담은 성분이 없어요'), findsNothing);
  });

  testWidgets('제품과 성분이 각 섹션에 나뉘어 남는다', (tester) async {
    final c = await pump(tester, '/shelf');

    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 1,
          name: '아토베리어365 크림',
          isProduct: true,
          kind: PreferenceKind.like,
        ));
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 106,
          name: '나이아신아마이드',
          isProduct: false,
          kind: PreferenceKind.dislike,
        ));
    await tester.pumpAndSettle();

    expect(find.text('아토베리어365 크림'), findsOneWidget);
    expect(find.text('선호 제품'), findsOneWidget);
    expect(find.text('나이아신아마이드'), findsOneWidget);
    expect(find.text('기피 성분'), findsOneWidget);
    // 빈 안내는 사라져야 한다.
    expect(find.textContaining('아직 담은'), findsNothing);
  });
}
