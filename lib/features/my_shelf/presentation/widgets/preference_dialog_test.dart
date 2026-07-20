// 선호/기피 팝업 검증 — 검색한 종류에 맞는 3개 버튼만 떠야 한다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/my_shelf/presentation/widgets/preference_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// 팝업을 띄우고 결과를 받아두는 테스트용 화면.
  Future<PreferenceKind?> open(WidgetTester tester,
      {required bool isProduct}) async {
    PreferenceKind? result;
    var done = false;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            result = await showPreferenceDialog(ctx,
                name: '테스트항목', isProduct: isProduct);
            done = true;
          },
          child: const Text('열기'),
        ),
      ),
    ));

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    return done ? result : null;
  }

  testWidgets('제품이면 선호/기피 제품 + 취소 3개가 뜬다', (tester) async {
    await open(tester, isProduct: true);

    expect(find.text('선호 제품으로 추가'), findsOneWidget);
    expect(find.text('기피 제품으로 추가'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    // 성분 문구는 없어야 한다.
    expect(find.text('선호 성분으로 추가'), findsNothing);
  });

  testWidgets('성분이면 선호/기피 성분 + 취소 3개가 뜬다', (tester) async {
    await open(tester, isProduct: false);

    expect(find.text('선호 성분으로 추가'), findsOneWidget);
    expect(find.text('기피 성분으로 추가'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('선호 제품으로 추가'), findsNothing);
  });

  testWidgets('선호를 누르면 like 가 돌아온다', (tester) async {
    PreferenceKind? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            result = await showPreferenceDialog(ctx,
                name: '테스트항목', isProduct: true);
          },
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('선호 제품으로 추가'));
    await tester.pumpAndSettle();

    expect(result, PreferenceKind.like);
  });

  testWidgets('취소를 누르면 아무것도 안 담긴다 (null)', (tester) async {
    PreferenceKind? result;
    var finished = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => ElevatedButton(
          onPressed: () async {
            result = await showPreferenceDialog(ctx,
                name: '테스트항목', isProduct: true);
            finished = true;
          },
          child: const Text('열기'),
        ),
      ),
    ));
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(result, isNull);
  });
}
