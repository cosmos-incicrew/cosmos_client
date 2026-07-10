import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/bsti_result.dart';

/// BSTI 결과 화면 — 4축 비율 + 타입 코드/별명 + 권장/주의 성분.
/// (피그마: OSPW, "나의 피부타입은", O 지성 75% / D 건성 25%, 권장성분/주의성분)
///
/// TODO: 실제 결과는 서버 응답으로 교체. 지금은 목업.
class BstiResultScreen extends StatelessWidget {
  const BstiResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: provider에서 실제 결과 조회. 지금은 피그마 예시값 목업.
    const result = BstiResult(
      typeCode: 'OSPW',
      typeName: '진정이 먼저인 풀코스 케어 수련생',
      axes: [
        BstiAxis(leftCode: 'O', leftLabel: '지성', leftPercent: 75, rightCode: 'D', rightLabel: '건성'),
        BstiAxis(leftCode: 'S', leftLabel: '민감', leftPercent: 60, rightCode: 'R', rightLabel: '저항'),
        BstiAxis(leftCode: 'P', leftLabel: '색소', leftPercent: 55, rightCode: 'N', rightLabel: '비색소'),
        BstiAxis(leftCode: 'W', leftLabel: '주름', leftPercent: 70, rightCode: 'T', rightLabel: '탱탱'),
      ],
      recommendedIngredients: ['나이아신아마이드', '글리세롤', '히알루론산'],
      cautionIngredients: ['알코올', '향료'],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('BSTI 결과')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('나의 피부타입은',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(result.typeCode,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
          Text(result.typeName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          for (final axis in result.axes) _axisBar(axis),
          const SizedBox(height: 24),
          _ingredientSection('권장성분', result.recommendedIngredients, AppColors.safe),
          const SizedBox(height: 16),
          _ingredientSection('주의성분', result.cautionIngredients, AppColors.danger),
        ],
      ),
    );
  }

  Widget _axisBar(BstiAxis axis) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${axis.leftCode} ${axis.leftLabel} ${axis.leftPercent}%',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text('${axis.rightCode} ${axis.rightLabel} ${axis.rightPercent}%',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: axis.leftPercent / 100,
              minHeight: 10,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ingredientSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map((i) => Chip(
                    label: Text(i),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
