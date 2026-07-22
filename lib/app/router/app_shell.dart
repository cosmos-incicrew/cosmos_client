import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_drawer.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 메인 화면 콘텐츠 최대 폭.
///
/// 폰 시안 기준 레이아웃이라, 넓은 창(웹·태블릿)에서 그대로 늘리면 깨진다.
/// 콘텐츠를 이 폭까지만 늘리고 가운데 정렬한다 — 반응형의 기준값.
const double kContentMaxWidth = 480;

/// 화면 콘텐츠를 [kContentMaxWidth] 로 제한해 가운데 정렬.
///
/// 쉘 안 화면은 쉘이 이미 감싸주므로 따로 쓸 필요 없다.
/// 쉘 밖 화면(스플래시·온보딩·BSTI 등 전체 화면)에서 body 에 감싼다.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: child,
      ),
    );
  }
}

/// 하단 탭 네비게이션 쉘 + 고정 헤더.
///
/// 헤더(햄버거·COSMOS 로고·마이)와 푸터(화장대/홈/마이 탭)는 **모든 메인
/// 화면에서 고정**이다 — 쉘 안 화면들은 자기 AppBar 를 갖지 않는다.
/// (스플래시·온보딩 등 로그인 전 진입 흐름만 쉘 밖)
///
/// ⚠️ destinations 순서는 app_router.dart 의 branches 순서와 같아야 한다.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 72,
        leadingWidth: 64,
        // 어느 화면에서든 메뉴 서랍.
        leading: Builder(
          builder: (ctx) => IconButton(
            icon:
                const Icon(Icons.menu, color: AppColors.textPrimary, size: 30),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Image.asset(
            AppAssets.logoWordmark,
            height: 44,
            errorBuilder: (_, __, ___) =>
                Text('COSMOS', style: AppTextStyles.pointBoldEn(size: 22)),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: AppColors.textPrimary, size: 30),
            onPressed: () => context.go('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      // 반응형: 넓은 창에서도 콘텐츠는 폰 폭으로 가운데 정렬.
      body: ContentWidth(child: navigationShell),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shelves),
            selectedIcon: Icon(Icons.shelves),
            label: '화장대',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
