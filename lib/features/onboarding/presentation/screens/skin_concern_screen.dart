import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 온보딩 · 피부고민 선택 — 여드름/트러블, 블랙헤드, 모공 등 다중 선택.
/// (피그마: 피부고민 칩 선택 → NEXT)
/// 다음 단계는 등록 완료 화면(BSTI vs 홈 선택).
class SkinConcernScreen extends StatelessWidget {
  const SkinConcernScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: '피부고민 선택',
      description: '여드름/트러블 · 블랙헤드 · 모공 등 (다중 선택)',
      actions: [
        (label: '다음', onTap: () => context.push('/onboarding/done')),
      ],
    );
  }
}
