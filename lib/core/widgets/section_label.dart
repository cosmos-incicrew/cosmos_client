import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 해설·보고서 공용 소제목 — 색 막대 + 굵은 제목.
///
/// "성분 역할 / 주의사항 / 추천 근거"처럼 긴 본문을 구획해 읽기 쉽게 한다.
/// 주의 계열 소제목은 [color] 에 danger 를 넘긴다.
class SectionLabel extends StatelessWidget {
  const SectionLabel(
    this.text, {
    super.key,
    this.color = AppColors.primary,
    this.dense = false,
  });

  final String text;
  final Color color;

  /// 토글 내부처럼 좁은 곳은 살짝 작게.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 4 : 6),
      child: Row(
        children: [
          Container(width: 4, height: dense ? 12 : 15, color: color),
          const SizedBox(width: 7),
          Text(text,
              style: (dense ? AppTextStyles.caption : AppTextStyles.body)
                  .copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
