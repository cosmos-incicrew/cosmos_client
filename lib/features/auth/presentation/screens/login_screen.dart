import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

/// 로그인 시트 — 직전 화면(온보딩) 위에 어둠과 함께 올라오는 모달 바텀시트.
///
/// [LoginSheet.show]로 띄운다. 별도 페이지가 아니라 뒤 화면이 비쳐 보이는 모달.
/// 구성: 소셜 원형 아이콘 3개(카카오·네이버·구글) → "또는" 구분선 →
/// "로그인 없이 시작하기" 회색 텍스트. 색/폰트는 앱 컨셉, 게스트 플로우 유지.
class LoginSheet extends ConsumerWidget {
  const LoginSheet({super.key});

  /// 현재 화면 위에 로그인 시트를 띄운다. (배경 어두워짐 + 하단에서 슬라이드업)
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (_) => const LoginSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 시트 핸들.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 소셜 로그인 원형 아이콘 3개.
            // 로고 PNG가 이미 브랜드 색 원을 포함하므로 배경 원을 겹치지 않는다.
            // (구글만 원 배경이 없어 흰 원을 깔아준다)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialCircle(
                  logo: AppAssets.kakao,
                  fallbackIcon: Icons.chat_bubble,
                  fallbackBackground: const Color(0xFFFEE500),
                  fallbackForeground: const Color(0xFF3C1E1E),
                  // Supabase OAuth — 카카오 동의 화면으로 리다이렉트.
                  onTap: () => _oauthLogin(context, ref, _OAuth.kakao),
                ),
                const SizedBox(width: 24),
                _SocialCircle(
                  logo: AppAssets.naver,
                  fallbackIcon: Icons.check_circle,
                  fallbackBackground: const Color(0xFF03C75A),
                  fallbackForeground: Colors.white,
                  // ⚠️ 목업 — 실제 연동 계획 없음. 누르면 성공.
                  onTap: () => _naverMockLogin(context, ref),
                ),
                const SizedBox(width: 24),
                _SocialCircle(
                  logo: AppAssets.google,
                  fallbackIcon: Icons.g_mobiledata,
                  fallbackBackground: Colors.white,
                  fallbackForeground: Colors.black87,
                  // 구글 로고는 투명 배경 → 흰 원을 깔아 통일.
                  padBackground: Colors.white,
                  // Supabase OAuth — 구글 동의 화면으로 리다이렉트.
                  onTap: () => _oauthLogin(context, ref, _OAuth.google),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // "또는" 구분선.
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.outline)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는', style: AppTextStyles.caption),
                ),
                Expanded(child: Divider(color: AppColors.outline)),
              ],
            ),
            const SizedBox(height: 16),
            // 로그인 없이 시작하기 (게스트) → 팝업.
            // 소셜 로그인이 주(主)이므로 강조하지 않고 회색 텍스트만.
            TextButton(
              onPressed: () => _guestFlow(context, ref),
              child: const Text('로그인 없이 시작하기',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  void _notReady(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('소셜 로그인은 준비 중입니다 (SDK 연동 예정)')),
      );
  }

  /// 카카오·구글 로그인 — Supabase OAuth 리다이렉트를 시작한다.
  ///
  /// 성공하면 브라우저가 동의 화면으로 넘어가므로 **여기서 화면 이동을 하지
  /// 않는다.** 돌아오면 앱이 재시작되고 라우터가 세션을 보고 보낸다.
  /// Supabase 미설정([UnimplementedError])이면 "준비 중" 안내.
  Future<void> _oauthLogin(
    BuildContext context,
    WidgetRef ref,
    _OAuth which,
  ) async {
    final ctrl = ref.read(authControllerProvider.notifier);
    try {
      switch (which) {
        case _OAuth.kakao:
          await ctrl.signInWithKakao();
        case _OAuth.google:
          await ctrl.signInWithGoogle();
      }
    } on UnimplementedError {
      if (context.mounted) _notReady(context);
    }
  }

  /// 네이버 로그인 — ⚠️ 목업 (누르면 성공).
  /// 로그인 후 온보딩을 마쳤으면 홈, 아니면 프로필 등록으로 보낸다.
  Future<void> _naverMockLogin(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signInWithNaver();
    if (!context.mounted) return;

    // 로그인 시트를 닫고 다음 단계로.
    Navigator.of(context).pop();
    if (!context.mounted) return;

    final auth = ref.read(authControllerProvider);
    if (auth.onboarded) {
      context.go('/home');
    } else {
      context.push('/onboarding/profile');
    }
  }

  /// 게스트 팝업: "비회원은 맞춤 추천 불가. 계속?"
  /// - 홈으로: 게스트로 홈 진입 (온보딩 건너뜀)
  /// - 회원가입 계속: 프로필 등록으로
  Future<void> _guestFlow(BuildContext context, WidgetRef ref) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Text(
          '비회원으로 이용시,\n맞춤형 제품추천이 불가합니다.\n\n회원가입을 계속 진행할까요?',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'home'),
            child: const Text('홈으로',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'signup'),
            child: const Text('계속하기'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    if (choice == 'home') {
      final ctrl = ref.read(authControllerProvider.notifier);
      await ctrl.signInAsGuest();
      ctrl.completeOnboarding();
      if (context.mounted) context.go('/home');
    } else if (choice == 'signup') {
      // 로그인 시트를 닫고 프로필 등록으로.
      Navigator.of(context).pop();
      context.push('/onboarding/profile');
    }
  }
}

/// 소셜 로그인 원형 아이콘.
///
/// 로고 PNG가 이미 브랜드 색 원을 포함하므로 로고를 원형으로 꽉 채워 보여준다.
/// - [padBackground]: 로고 배경이 투명한 경우(구글) 뒤에 깔 원 색.
/// - 로고 로드 실패 시 [fallbackBackground] 원 + [fallbackIcon]으로 대체.
class _SocialCircle extends StatelessWidget {
  const _SocialCircle({
    required this.logo,
    required this.fallbackIcon,
    required this.fallbackBackground,
    required this.fallbackForeground,
    required this.onTap,
    this.padBackground,
  });

  static const double _size = 56;

  final String? logo;
  final IconData fallbackIcon;
  final Color fallbackBackground;
  final Color fallbackForeground;
  final Color? padBackground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logoPath = logo;
    // 투명 심볼 로고(구글 G)는 흰 원 + 안쪽 여백을 두고 작게.
    // 원 배경이 포함된 로고(카카오/네이버)는 원을 꽉 채운다.
    final isSymbolOnly = padBackground != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: ClipOval(
        child: SizedBox(
          width: _size,
          height: _size,
          child: logoPath == null
              ? _fallback()
              : ColoredBox(
                  color: padBackground ?? Colors.transparent,
                  child: Padding(
                    // 심볼 로고만 여백을 줘서 원 안에 작게 앉힌다.
                    padding: EdgeInsets.all(isSymbolOnly ? 14 : 0),
                    child: Image.asset(
                      logoPath,
                      fit: isSymbolOnly ? BoxFit.contain : BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallback(),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _fallback() {
    return ColoredBox(
      color: fallbackBackground,
      child: Icon(fallbackIcon, color: fallbackForeground, size: 26),
    );
  }
}

/// Supabase OAuth 로 리다이렉트하는 소셜 로그인 종류.
enum _OAuth { kakao, google }
