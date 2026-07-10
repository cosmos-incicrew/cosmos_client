import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// BSTI 검사 시작 화면 — "16가지 유형의 피부 MBTI 검사" + START.
class BstiIntroScreen extends StatelessWidget {
  const BstiIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'BSTI 검사',
      description: '25가지 문항으로 알아보는 16개 유형의 피부 MBTI',
      actions: [
        (label: 'START', onTap: () => context.push('/bsti/test')),
      ],
    );
  }
}
