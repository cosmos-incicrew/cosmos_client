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
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 78,
          backgroundColor: AppColors.background,
          indicatorColor: AppColors.primaryLight,
          // 라벨: 앱 컨셉대로 영문 갈무리 픽셀 폰트, 기존보다 키움.
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppTextStyles.pointBoldEn(
              size: 13,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: _FooterIcon(
                  asset: AppAssets.footerShelf,
                  fallback: Icons.shelves,
                  selected: false),
              selectedIcon: _FooterIcon(
                  asset: AppAssets.footerShelf,
                  fallback: Icons.shelves,
                  selected: true),
              label: 'SHELF',
            ),
            NavigationDestination(
              icon: _FooterIcon(
                  asset: AppAssets.footerHome,
                  fallback: Icons.home_outlined,
                  selected: false),
              selectedIcon: _FooterIcon(
                  asset: AppAssets.footerHome,
                  fallback: Icons.home,
                  selected: true),
              label: 'HOME',
            ),
            NavigationDestination(
              icon: _FooterIcon(
                  asset: AppAssets.footerMy,
                  fallback: Icons.person_outline,
                  selected: false),
              selectedIcon: _FooterIcon(
                  asset: AppAssets.footerMy,
                  fallback: Icons.person,
                  selected: true),
              label: 'MY',
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단바 아이콘 — assets/icons/footer/ 의 PNG 를 쓰고,
/// 파일이 아직 없으면 [fallback] Material 아이콘으로 대체한다.
/// 선택 안 된 탭은 반투명으로 보여준다.
class _FooterIcon extends StatelessWidget {
  const _FooterIcon({
    required this.asset,
    required this.fallback,
    required this.selected,
  });

  final String asset;
  final IconData fallback;
  final bool selected;

  static const double _size = 30; // 기존(24)보다 키움

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: selected ? 1.0 : 0.45,
      child: Image.asset(
        asset,
        width: _size,
        height: _size,
        errorBuilder: (_, __, ___) => Icon(
          fallback,
          size: _size,
          color: selected ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}
