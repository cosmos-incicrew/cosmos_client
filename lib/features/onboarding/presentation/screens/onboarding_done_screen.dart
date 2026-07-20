import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';
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

    return PlaceholderScreen(
      title: '프로필 등록 완료',
      description: '이제 피부타입을 검사하고 나만의 화장품 성분을 추천받아보세요',
      actions: [
        (label: 'BSTI 검사 하러가기', onTap: () => finish('/bsti')),
        (label: '홈으로', onTap: () => finish('/home')),
      ],
    );
  }
}
