import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/bsti/presentation/screens/bsti_intro_screen.dart';
import '../../features/bsti/presentation/screens/bsti_result_screen.dart';
import '../../features/bsti/presentation/screens/bsti_test_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/my_shelf/presentation/screens/my_shelf_screen.dart';
import '../../features/my_shelf/presentation/screens/shelf_add_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import '../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../features/onboarding/presentation/screens/skin_concern_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/recommendation/presentation/screens/recommendation_screen.dart';
import 'app_shell.dart';

// 쉘 브랜치별 네비게이터 키
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shelfKey = GlobalKey<NavigatorState>(debugLabel: 'shelf');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

/// 앱 라우터.
///
/// 인증 상태에 따라 로그인 화면 <-> 메인 쉘로 리다이렉트한다.
/// (게스트 로그인도 isSignedIn == true 로 취급되어 메인으로 진입)
///
/// 화면 흐름 (피그마 기준):
///   로그인 → 온보딩(인트로→프로필→피부고민) → 홈
///   홈 = 허브: BSTI 검사 / 나의 화장대 / 맞춤 추천 진입
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
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // 온보딩 (쉘 밖, 전체 화면)
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const OnboardingIntroScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const ProfileSetupScreen(),
          ),
          GoRoute(
            path: 'concerns',
            builder: (context, state) => const SkinConcernScreen(),
          ),
        ],
      ),

      // BSTI 검사 (쉘 밖, 전체 화면)
      GoRoute(
        path: '/bsti',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const BstiIntroScreen(),
        routes: [
          GoRoute(
            path: 'test',
            builder: (context, state) => const BstiTestScreen(),
          ),
          GoRoute(
            path: 'result',
            builder: (context, state) => const BstiResultScreen(),
          ),
        ],
      ),

      // 화장대에 추가 (검색·자동완성, 쉘 밖 전체 화면)
      GoRoute(
        path: '/shelf/add',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const ShelfAddScreen(),
      ),

      // 맞춤 추천 (쉘 밖 전체 화면)
      GoRoute(
        path: '/recommendation',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const RecommendationScreen(),
      ),

      // 하단 탭 쉘 (홈 / 화장대 / 마이)
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
            navigatorKey: _shelfKey,
            routes: [
              GoRoute(
                path: '/shelf',
                builder: (context, state) => const MyShelfScreen(),
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
