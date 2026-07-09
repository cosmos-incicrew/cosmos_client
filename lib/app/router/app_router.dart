import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import 'app_shell.dart';

// 쉘 브랜치별 네비게이터 키
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// 앱 라우터.
///
/// 인증 상태에 따라 로그인 화면 <-> 메인 쉘로 리다이렉트합니다.
/// (게스트 로그인도 isSignedIn == true 로 취급되어 메인으로 진입)
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(const AuthState());
  ref.listen(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);

      // 세션 복원 중이면 대기 (splash 대체)
      if (auth.status == AuthStatus.unknown) return null;

      final loggingIn = state.matchedLocation == '/login';

      if (!auth.isSignedIn) {
        return loggingIn ? null : '/login';
      }
      // 로그인 완료 상태에서 /login 에 있으면 홈으로
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // 상세/검색은 쉘 밖(전체 화면)으로 push
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      // 하단 탭 쉘
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
