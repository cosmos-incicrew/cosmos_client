import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// BSTI 설문 진행 화면 — Q1..Q25 → "분석중" → 결과로 이동.
/// (피그마: Q1./Q2. 문항, 진행 → 분석중 로딩)
class BstiTestScreen extends StatelessWidget {
  const BstiTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'BSTI 설문 (Q1~Q25)',
      description: '문항 응답 → 분석중 → 결과 산출 (채점은 서버 담당)',
      actions: [
        (label: '결과 보기', onTap: () => context.pushReplacement('/bsti/result')),
      ],
    );
  }
}
