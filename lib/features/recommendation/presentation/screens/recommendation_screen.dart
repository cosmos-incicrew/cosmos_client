import 'package:flutter/material.dart';

import '../../../../core/widgets/placeholder_screen.dart';

/// 맞춤 제품·성분 추천 — 프로필 + BSTI + 화장대 기반.
/// (피그마: 홈 "맞춤 제품추천". 서버 recommendation 모듈 = 근거 기반 생성)
///
/// 서버 규칙: 검색 점수 미달 시 "확인 불가" 정형 응답. 안전 단정 금지.
class RecommendationScreen extends StatelessWidget {
  const RecommendationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlaceholderScreen(
      title: '맞춤 추천',
      description: '프로필 · BSTI · 화장대 기반 성분/제품 추천 (서버 근거 기반 생성)',
    );
  }
}
