import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 온보딩 · 프로필 등록 — 닉네임 / 나이 / 성별 입력.
/// (피그마: My Profile — 닉네임·나이·성별)
class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: '프로필 등록',
      description: '닉네임 · 나이 · 성별 입력',
      actions: [
        (label: '피부고민 선택으로', onTap: () => context.push('/onboarding/concerns')),
      ],
    );
  }
}
