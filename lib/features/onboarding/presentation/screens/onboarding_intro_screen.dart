import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 온보딩 인트로 — BSTI 소개 / OSPT·OSPW 피부타입 설명 / 서비스 소개 슬라이드.
/// (피그마: Onboarding 여러 장 → "내 화장대 종합보고서부터 나와 꼭 맞는 제품추천까지")
class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: '온보딩 · 서비스 소개',
      description: 'BSTI 16타입 소개, OSPT/OSPW 축 설명, 서비스 안내 슬라이드',
      actions: [
        (label: '프로필 등록으로', onTap: () => context.push('/onboarding/profile')),
      ],
    );
  }
}
