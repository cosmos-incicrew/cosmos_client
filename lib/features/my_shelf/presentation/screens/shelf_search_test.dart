// 제품·성분 검색 화면 동작 검증 — 입력 → 필터 → 결과 → 상세 이동.
// 소스 옆에 둔다. 실행: flutter test lib/features/my_shelf/
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/core/mock/mock_data.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/shelf_add_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 검색 화면이 선호/기피 provider 를 읽으므로 ProviderScope 로 감싼다.
  Widget app() =>
      const ProviderScope(child: MaterialApp(home: ShelfAddScreen()));

  testWidgets('입력 전에는 안내 문구', (tester) async {
    await tester.pumpWidget(app());
    expect(find.text('제품명이나 성분명을 검색해보세요'), findsOneWidget);
  });

  testWidgets('제품명으로 검색하면 결과가 나온다', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), '아토베리어');
    await tester.pump();
    // 아토베리어 제품이 여러 개 잡힌다.
    expect(find.textContaining('아토베리어365'), findsWidgets);
  });

  testWidgets('성분명으로 검색하면 성분 결과가 나온다', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), '글리세린');
    await tester.pump();
    expect(find.text('글리세린'), findsWidgets);
  });

  testWidgets('없는 검색어는 결과 없음', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), 'zzz없는제품');
    await tester.pump();
    expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('제품을 누르면 상세로 이동해 대표성분이 보인다', (tester) async {
    await tester.pumpWidget(app());
    await tester.enterText(find.byType(TextField), '하이드로 에센스');
    await tester.pump();
    // 첫 제품 탭.
    await tester.tap(find.text('아토베리어365 하이드로 에센스').first);
    await tester.pumpAndSettle();
    // 상세 화면 요소. (성분 자세히 보기는 스크롤 아래에 있을 수 있어 스크롤)
    expect(find.text('대표성분'), findsOneWidget);
    expect(find.text('트리플 리피드 콤플렉스'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('성분 자세히 보기'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('성분 자세히 보기'), findsOneWidget);
  });

  test('시안 제품(하이드로 에센스)이 성분과 연결돼 있다', () {
    final p = mockProducts.firstWhere((e) => e.id == 1);
    expect(p.name, contains('하이드로 에센스'));
    expect(p.ingredientIds, isNotEmpty);
  });
}
