// BSTI 설문 화면 상호작용 검증 — 보기 선택 → 다음 진행 → 문항 이동.
// 소스와 같은 폴더에 둔다. 실행: flutter test lib/features/bsti/
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/bsti/bsti_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // 라우터로 감싸 pushReplacement('/bsti/result')가 동작하게 한다.
  Widget app() {
    final router = GoRouter(
      initialLocation: '/bsti/test',
      routes: [
        GoRoute(
          path: '/bsti/test',
          builder: (_, __) => const BstiTestScreen(),
        ),
        GoRoute(
          path: '/bsti/result',
          builder: (_, state) => Scaffold(
            body: Text('RESULT:${state.uri.queryParameters['code']}'),
          ),
        ),
      ],
    );
    // 설문 완료 시 결과를 provider 에 저장하므로 ProviderScope 로 감싼다.
    return ProviderScope(child: MaterialApp.router(routerConfig: router));
  }

  testWidgets('첫 문항이 Q1과 전체 문항 수를 보여준다', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Q1'), findsOneWidget);
    expect(find.text('1 / ${kBstiQuestions.length}'), findsOneWidget);
    // 첫 문항 텍스트가 보인다.
    expect(find.text(kBstiQuestions.first.text), findsOneWidget);
  });

  testWidgets('보기 선택 전에는 다음 버튼이 비활성', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull); // 미선택 → 비활성
  });

  testWidgets('전 문항을 최고점(보기1)으로 답하면 OSPW 결과로 이동', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    for (var i = 0; i < kBstiQuestions.length; i++) {
      // 각 문항의 첫 번째 보기(= score 4, 높은 극)를 탭.
      final firstOptionLabel = kBstiQuestions[i].options.first.label;
      await tester.tap(find.text(firstOptionLabel).last);
      await tester.pump();
      // 다음/결과 버튼 탭.
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

    // 전부 score 4 → 코드 OSPW.
    expect(find.text('RESULT:OSPW'), findsOneWidget);
  });
}
