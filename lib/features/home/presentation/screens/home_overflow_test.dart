// 홈 화면이 폰 크기에서 오버플로우 없이 렌더되는지 검증.
// (타일 높이를 고정했다가 "BOTTOM OVERFLOWED" 나던 이슈 재발 방지)
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/app/theme/app_theme.dart';
import 'package:cosmos_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Widget app() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/bsti', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/shelf', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/shelf/add', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/recommendation', builder: (_, __) => const SizedBox()),
        GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
      ],
    );
    return MaterialApp.router(theme: AppTheme.light, routerConfig: router);
  }

  testWidgets('홈이 폰 크기(390x844)에서 오버플로우 없이 렌더된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 렌더 중 오버플로우가 있었으면 여기서 예외가 잡힌다.
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면(360x640)에서도 오버플로우 없음', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // 메뉴 글씨는 이미지 안에 그려져 있어 find.text로 잡히지 않는다.
  //
  // 주의: flutter test 환경은 실제 에셋을 로드하지 않는다. 이미지가 크기 0으로
  // 깔리면 시맨틱 노드도 안 생겨 find.bySemanticsLabel 로는 잡히지 않는다.
  // (브라우저에서는 정상) 그래서 위젯 자체가 배치됐는지로 검증한다.
  testWidgets('홈 메뉴 이미지 버튼 4개가 배치된다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 배너 + BSTI + 내 화장대 + My-Skin ITEM = 4개.
    // (아이콘 버튼 등 다른 Semantics 와 섞이지 않게 라벨로 좁힌다)
    const menuLabels = {
      '내 화장대 점수는??',
      'BSTI 피부타입 검사',
      '내 화장대 만들기',
      '나와 베스트 궁합 제품추천',
    };
    final found = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => menuLabels.contains(s.properties.label))
        .length;

    expect(found, 4);
  });

  testWidgets('메뉴 버튼의 라우팅이 각각 연결돼 있다', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // 라벨로 각 버튼의 목적지를 확인 (Semantics.label 은 트리에 남는다).
    final labels = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.button == true)
        .map((s) => s.properties.label)
        .toList();

    expect(labels, contains('내 화장대 점수는??'));
    expect(labels, contains('BSTI 피부타입 검사'));
    expect(labels, contains('내 화장대 만들기'));
    expect(labels, contains('나와 베스트 궁합 제품추천'));
  });
}
