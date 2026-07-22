// 데이터가 하나도 없을 때(백엔드 연동 전) 화면이 터지지 않는지 검증.
//
// 저장소가 빈 결과를 주는 지금 상태에서 각 화면을 실제로 띄워보고,
// 예외·오버플로우가 나면 실패시킨다.
// "빈 화면"은 괜찮지만 "에러 화면"은 안 된다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/theme/app_theme.dart';
import 'package:cosmos_app/features/bsti/bsti_result_screen.dart';
import 'package:cosmos_app/features/compare/presentation/screens/product_compare_screen.dart';
import 'package:cosmos_app/features/onboarding/presentation/screens/onboarding_done_screen.dart';
import 'package:cosmos_app/features/onboarding/presentation/screens/skin_concern_screen.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/ingredient/data/models/ingredient.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/ingredient_detail_screen.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/my_shelf_screen.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/product_detail_screen.dart';
import 'package:cosmos_app/features/my_shelf/presentation/screens/shelf_add_screen.dart';
import 'package:cosmos_app/features/product/data/models/product.dart';
import 'package:cosmos_app/features/recommendation/presentation/screens/recommendation_screen.dart';
import 'package:cosmos_app/features/report/presentation/screens/report_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmos_app/features/onboarding/data/profile_repository.dart';

import 'support/fake_repositories.dart';

void main() {
  /// 화면 하나를 폰 크기로 띄우고, 예외 없이 안착하는지 본다.
  Future<ProviderContainer> show(
    WidgetTester tester,
    Widget screen, {
    void Function(ProviderContainer)? setup,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // BSTI 저장이 프로필 POST 를 타므로 서버에 안 나가는 대역만 끼운다.
    // (제품·성분까지 페이크로 바꾸면 화면에 그려지는 내용이 달라진다)
    final container = ProviderContainer(overrides: [
      profileRepositoryProvider.overrideWithValue(const FakeProfileRepository()),
    ]);
    addTearDown(container.dispose);
    setup?.call(container);

    // 화면 안에서 context.go/push 를 쓰므로 라우터를 붙여준다.
    final router = GoRouter(
      initialLocation: '/x',
      routes: [
        GoRoute(path: '/x', builder: (_, __) => screen),
        GoRoute(path: '/home', builder: (_, __) => const Text('홈')),
        GoRoute(path: '/shelf', builder: (_, __) => const Text('화장대')),
        GoRoute(path: '/shelf/add', builder: (_, __) => const Text('검색')),
        GoRoute(path: '/bsti/test', builder: (_, __) => const Text('검사')),
      ],
    );

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: router,
      ),
    ));
    // 로딩 스피너가 걷히고 빈 상태로 안착할 때까지.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    return container;
  }

  const sampleProduct = Product(
    id: 1,
    name: '샘플 제품',
    brand: '샘플',
    mainCategory: '스킨케어',
    subCategory: '크림',
    ingredientIds: [101],
  );

  const sampleIngredient = Ingredient(
    id: 101,
    nameKor: '샘플 성분',
    nameEng: 'Sample',
    bstiIngredientId: 'gly',
  );

  testWidgets('검색 화면 — 데이터 없어도 안 터진다', (tester) async {
    await show(tester, const ShelfAddScreen());
    expect(tester.takeException(), isNull);
  });

  testWidgets('검색 화면 — 검색해도 안 터진다 (결과 없음)', (tester) async {
    await show(tester, const ShelfAddScreen());
    await tester.enterText(find.byType(TextField), '아무거나');
    await tester.pump(const Duration(milliseconds: 400)); // 디바운스
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // 에러가 아니라 "결과 없음"이 떠야 한다.
    expect(find.textContaining('검색 결과가 없어요'), findsOneWidget);
  });

  testWidgets('화장대 화면 — 빈 상태로 안착한다', (tester) async {
    await show(tester, const MyShelfScreen());
    expect(tester.takeException(), isNull);
  });

  testWidgets('제품 상세 — 성분을 못 받아도 안 터진다', (tester) async {
    await show(tester, const ProductDetailScreen(product: sampleProduct));
    expect(tester.takeException(), isNull);
  });

  testWidgets('성분 상세 — 제품을 못 받아도 안 터진다', (tester) async {
    await show(tester,
        const IngredientDetailScreen(ingredient: sampleIngredient));
    expect(tester.takeException(), isNull);
  });

  testWidgets('추천 화면 — 빈 상태 문구가 뜬다', (tester) async {
    await show(tester, const RecommendationScreen());
    expect(tester.takeException(), isNull);
    expect(find.textContaining('추천할 제품을 찾지 못했어요'), findsOneWidget);
  });

  testWidgets('보고서 — 검사 전에도 안 터진다', (tester) async {
    await show(tester, const ReportScreen());
    expect(tester.takeException(), isNull);
  });

  testWidgets('보고서 — 검사 + 제품 담아도 안 터진다', (tester) async {
    await show(tester, const ReportScreen(), setup: (c) {
      c.read(userProfileProvider.notifier).saveBstiType('OSPW');
      c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
            id: 1,
            name: '샘플 제품',
            isProduct: true,
            kind: PreferenceKind.like,
          ));
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('BSTI 결과 — 두 버튼이 뜨고 안 터진다', (tester) async {
    await show(tester, const BstiResultScreen(typeCode: 'OSPW'));
    expect(tester.takeException(), isNull);

    // 버튼은 ListView 맨 아래에 있다 — 끝까지 스크롤해서 확인.
    await tester.scrollUntilVisible(
      find.text('내 화장대 만들러 가기'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('내 화장대 만들러 가기'), findsOneWidget);
    expect(find.text('홈으로'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('제품 비교 — 데이터 없어도 안 터진다', (tester) async {
    await show(tester, const ProductCompareScreen());
    expect(tester.takeException(), isNull);
    // 2개 미만이면 비교하기가 비활성이어야 한다.
    expect(find.text('비교하기'), findsOneWidget);
  });

  testWidgets('피부고민 선택 — 칩 8개가 뜨고 안 터진다', (tester) async {
    await show(tester, const SkinConcernScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('모공'), findsOneWidget);
    expect(find.text('미백'), findsOneWidget);
  });

  testWidgets('온보딩 완료 — 두 동선이 뜨고 안 터진다', (tester) async {
    await show(tester, const OnboardingDoneScreen());
    expect(tester.takeException(), isNull);
    expect(find.text('BSTI 검사 하러가기'), findsOneWidget);
  });
}
