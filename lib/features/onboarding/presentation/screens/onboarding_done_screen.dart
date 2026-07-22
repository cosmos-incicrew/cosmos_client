import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_shell.dart';
import '../../../../app/theme/app_assets.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 온보딩 완료 — "프로필 등록 완료. 이제 피부타입을 검사하고
/// 나만의 화장품 성분을 추천받아보세요."
/// (피그마: 등록 완료 후 BSTI 바로 검사 vs 홈으로 선택)
///
/// 여기서 온보딩을 최종 완료 처리(completeOnboarding)한다.
class OnboardingDoneScreen extends ConsumerWidget {
  const OnboardingDoneScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void finish(String target) {
      ref.read(authControllerProvider.notifier).completeOnboarding();
      context.go(target);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ContentWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                // 고양이 로고 — 축하 분위기.
                Image.asset(
                  AppAssets.logoFull,
                  height: 140,
                  errorBuilder: (_, __, ___) => const Icon(Icons.celebration,
                      size: 80, color: AppColors.primary),
                ),
                const SizedBox(height: 28),
                Text('프로필 등록 완료!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pointMd(color: AppColors.primaryDark)),
                const SizedBox(height: 14),
                Text(
                  '이제 피부타입을 검사하고\n나만의 화장품 성분을 추천받아보세요',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                ),
                const Spacer(flex: 3),
                // BSTI 가 주 동선 — 검사를 해야 추천·보고서가 산다.
                PixelButton(
                  label: 'BSTI 검사 하러가기',
                  onPressed: () => finish('/bsti'),
                ),
                const SizedBox(height: 10),
                // 홈은 보조 동선 — 회색 텍스트.
                TextButton(
                  onPressed: () => finish('/home'),
                  child: const Text('나중에 하기 (홈으로)',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
