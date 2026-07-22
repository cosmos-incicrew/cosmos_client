import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/bsti/bsti_intro_screen.dart';
import '../../features/bsti/bsti_result_screen.dart';
import '../../features/bsti/bsti_result_store.dart';
import '../../features/bsti/bsti_test_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/my_shelf/presentation/screens/my_shelf_screen.dart';
import '../../features/compare/presentation/screens/product_compare_screen.dart';
import '../../features/ingredient/data/models/ingredient.dart';
import '../../features/my_shelf/presentation/screens/ingredient_detail_screen.dart';
import '../../features/my_shelf/presentation/screens/product_detail_screen.dart';
import '../../features/my_shelf/presentation/screens/shelf_add_screen.dart';
import '../../features/product/data/models/product.dart';
import '../../features/onboarding/presentation/screens/onboarding_done_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_intro_screen.dart';
import '../../features/onboarding/presentation/screens/profile_setup_screen.dart';
import '../../features/onboarding/presentation/screens/skin_concern_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/recommendation/presentation/screens/recommendation_screen.dart';
import '../../features/report/presentation/screens/report_screen.dart';
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
/// 화면 흐름 (피그마 와이어프레임 기준):
///   스플래시(고양이 로고) → 온보딩(소개) → 로그인(온보딩 끝 하단 시트)
///     ├─ 로그인 없이 시작 → 팝업 → 홈  (게스트)
///     └─ 회원가입 진행 → 프로필 → 피부고민 → 등록완료(BSTI vs 홈)
///   홈 = 허브: BSTI 검사 / 나의 화장대 / 맞춤 추천 진입
/// 인증 상태와 현재 위치로 갈 곳을 정한다. 그대로 두면 null.
///
/// 화면 없이 검증할 수 있도록 순수 함수로 뺐다 — 진입 흐름은 조건이 얽혀서
/// 한 번 어긋나면 "이미 로그인했는데 로그인 시트가 또 뜨는" 식으로 조용히 샌다.
String? redirectFor(AuthState auth, String location) {
  // 스플래시·온보딩은 진입 단계. (로그인은 온보딩 위 모달이라 별도 라우트가 없다)
  final inEntryFlow =
      location == '/splash' || location.startsWith('/onboarding');

  // 세션 복원 중 — 아직 아무것도 모른다. 복원이 끝나면 다시 평가된다.
  if (auth.status == AuthStatus.unknown) return null;

  // 로그인·온보딩을 마쳤으면 진입 화면을 다시 보여주지 않는다.
  // (앱을 다시 켤 때마다 START → 소개 → 로그인 시트를 또 보게 되던 문제)
  if (auth.onboarded) return inEntryFlow ? '/home' : null;

  // 로그인은 했는데 프로필이 없다 — 서버에 프로필이 생길 때까지 온보딩 안에 둔다.
  if (auth.isSignedIn) {
    // 하위 단계끼리는 자유 이동. 인트로(`/onboarding`)는 제외한다 — 로그인 시트가
    // 뜨는 화면이라, 여기 남기면 로그인에 성공해도 화면이 그대로다.
    return location.startsWith('/onboarding/') ? null : '/onboarding/profile';
  }

  // 미로그인이 메인(홈 등)에 직접 접근하면 처음으로.
  return inEntryFlow ? null : '/splash';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(const AuthState());
  ref.listen(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) =>
        redirectFor(ref.read(authControllerProvider), state.matchedLocation),
    routes: [
      // 스플래시 (앱 시작)
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const SplashScreen(),
      ),

      // 온보딩 (쉘 밖, 전체 화면)
      // 인트로(소개) → 로그인 시트(모달) → profile → concerns → done
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
          GoRoute(
            path: 'done',
            builder: (context, state) => const OnboardingDoneScreen(),
          ),
        ],
      ),

      // 하단 탭 쉘 (화장대 / 홈 / 마이) — 헤더·푸터는 쉘이 고정으로 가진다.
      // 메인 화면 전부가 브랜치 안에 있다 (쉘 밖은 스플래시·온보딩뿐).
      // ⚠️ 브랜치 순서 = AppShell.destinations 순서. 한쪽만 바꾸면 탭이 어긋난다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ── 화장대 탭: 검색·상세까지 이 브랜치 안 (푸터 유지) ──
          StatefulShellBranch(
            navigatorKey: _shelfKey,
            routes: [
              GoRoute(
                path: '/shelf',
                builder: (context, state) => const MyShelfScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const ShelfAddScreen(),
                  ),
                  // 상세는 검색 결과의 객체를 extra 로 받는다.
                  // 딥링크 등으로 extra 없이 들어오면 화장대로 돌려보낸다.
                  GoRoute(
                    path: 'product',
                    redirect: (context, state) =>
                        state.extra is Product ? null : '/shelf',
                    builder: (context, state) =>
                        ProductDetailScreen(product: state.extra! as Product),
                  ),
                  GoRoute(
                    path: 'ingredient',
                    redirect: (context, state) =>
                        state.extra is Ingredient ? null : '/shelf',
                    builder: (context, state) => IngredientDetailScreen(
                        ingredient: state.extra! as Ingredient),
                  ),
                ],
              ),
            ],
          ),
          // ── 홈 탭: 홈에서 진입하는 기능 화면 전부 ──
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/bsti',
                // 이미 검사를 했으면 소개를 건너뛰고 결과로 바로 간다.
                redirect: (context, state) {
                  final saved = ref.read(bstiResultProvider);
                  if (saved != null) return '/bsti/result?code=$saved';
                  return null;
                },
                builder: (context, state) => const BstiIntroScreen(),
                routes: [
                  GoRoute(
                    path: 'test',
                    builder: (context, state) => const BstiTestScreen(),
                  ),
                  GoRoute(
                    path: 'result',
                    builder: (context, state) => BstiResultScreen(
                      typeCode: state.uri.queryParameters['code'] ?? 'OSPW',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: '/recommendation',
                builder: (context, state) => const RecommendationScreen(),
              ),
              GoRoute(
                path: '/report',
                builder: (context, state) => const ReportScreen(),
              ),
              // 다중 제품 비교 (성분 구성 차이 + 해설)
              GoRoute(
                path: '/compare',
                builder: (context, state) => const ProductCompareScreen(),
              ),
            ],
          ),
          // ── 마이 탭 ──
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  // 별도 경로인 이유: `/onboarding/*` 은 온보딩 후 리다이렉트로 막힘.
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        const ProfileSetupScreen(isEditing: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
