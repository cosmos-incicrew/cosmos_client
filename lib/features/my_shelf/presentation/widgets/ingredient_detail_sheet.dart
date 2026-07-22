import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../ingredient/data/ingredient_providers.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';

/// 성분 해설 바텀시트 — ① GET /ingredients/{id}/detail.
///
/// 성분 이름을 누르면 올라온다. 명세 규칙:
/// - "확인 불가"는 에러가 아니다 → "아직 정보가 없습니다" 안내
/// - safety 는 세 형태로 표시가 다르다 ([공식 규제] 강조 / 일반 / 정보 없음)
/// - source_verified=false 면 본문은 보여주되 출처는 숨긴다
class IngredientDetailSheet extends ConsumerWidget {
  const IngredientDetailSheet({
    super.key,
    required this.ingredientId,
    this.fallbackName,
  });

  final int ingredientId;

  /// 해설이 오기 전(로딩)에도 이름은 보여준다.
  final String? fallbackName;

  static Future<void> show(
    BuildContext context, {
    required int ingredientId,
    String? fallbackName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => IngredientDetailSheet(
        ingredientId: ingredientId,
        fallbackName: fallbackName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ingredientDetailProvider(ingredientId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: async.when(
            loading: () => _frame(
              name: fallbackName,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, __) => _frame(
              name: fallbackName,
              child: Text('해설을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary)),
            ),
            data: (detail) => _frame(
              name: detail.name ?? fallbackName,
              child: _content(detail),
            ),
          ),
        ),
      ),
    );
  }

  Widget _frame({String? name, required Widget child}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 시트 핸들.
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        if (name != null) ...[
          Text(name, style: AppTextStyles.title),
          const SizedBox(height: 12),
        ],
        Flexible(child: SingleChildScrollView(child: child)),
      ],
    );
  }

  Widget _content(IngredientDetail detail) {
    // "확인 불가" — 에러가 아니라 정보가 아직 없는 것.
    if (detail.status == InsightStatus.unavailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('아직 정보가 없습니다',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
          if (detail.reason != null) ...[
            const SizedBox(height: 6),
            Text(detail.reason!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.body != null)
          Text(detail.body!, style: AppTextStyles.body.copyWith(height: 1.6)),
        const SizedBox(height: 16),
        _safety(detail),
        // 검증된 출처만 표시한다 (source_verified=false → 본문만).
        if (detail.sourceVerified && detail.referenceSource != null) ...[
          const SizedBox(height: 12),
          Text('출처: ${detail.referenceSource}',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  /// safety 세 형태 (명세 §2 기준표).
  Widget _safety(IngredientDetail detail) {
    switch (detail.safetyKind) {
      case SafetyKind.official:
        // 공식 규제 — 경고색 강조.
        return PixelBox(
          borderColor: AppColors.danger,
          fillColor: AppColors.danger.withValues(alpha: 0.08),
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(detail.safety!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textPrimary, height: 1.5)),
              ),
            ],
          ),
        );
      case SafetyKind.general:
        return Text(detail.safety!,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPrimary, height: 1.5));
      case SafetyKind.unknown:
        // "모른다"이지 "안전하다"가 아니다 — 안전으로 보이게 쓰지 않는다.
        return Text('안전성 정보 없음 (확인되지 않았다는 뜻이며, 안전하다는 뜻이 아닙니다)',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary));
    }
  }
}
