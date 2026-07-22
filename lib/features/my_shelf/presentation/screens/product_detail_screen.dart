import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../../core/widgets/screen_title.dart';
import '../../../bsti/bsti.dart';
import '../../../bsti/bsti_name_matcher.dart';
import '../../../ingredient/data/models/ingredient_insight.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/product_providers.dart';
import '../widgets/ingredient_detail_sheet.dart';

/// 제품 상세 화면 (명세 "화면 매핑" 기준).
///
///  제품명            ← 검색 결과 (Product)
///  대표성분 Top-3     ← ② product-summary top_ingredients
///  제품 해설 요약      ← ② summary ("주의:" 줄은 분리해 강조)
///  권장 피부타입      ← 대표성분 이름을 BSTI 사전과 매칭 (프론트 계산)
///  성분 목록          ← 검색엔진 ingredient_ids (개수) + 대표성분 행
///    └ 클릭 시        ← ① detail 바텀시트
///
/// TODO(BE): 전체 성분 **이름** 목록 엔드포인트가 없다. 지금은 이름이 있는
/// 대표성분만 행으로 보여주고 나머지는 개수로 안내한다.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productInsightProvider(product.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ScreenTitle(
                title: '제품 상세',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/shelf'),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => _message('제품 정보를 불러오지 못했어요'),
                data: (insight) => _body(context, insight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
        ),
      );

  Widget _body(
    BuildContext context,
    ({List<int> ingredientIds, ProductSummary summary}) insight,
  ) {
    final summary = insight.summary;
    final tops = summary.topIngredients;

    // 대표성분 이름 → BSTI 사전 매칭 → 권장 피부타입 (프론트 계산).
    final bstiIds = [
      for (final t in tops)
        if (bstiIdForNames(nameKr: t.name) != null)
          bstiIdForNames(nameKr: t.name)!,
    ];
    final matchedType =
        bstiIds.isEmpty ? null : BstiEngine.matchTypeByIngredients(bstiIds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        // 제품 이미지 (없으면 플레이스홀더).
        Center(
          child: Container(
            width: 150,
            height: 190,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _imgPlaceholder())
                : _imgPlaceholder(),
          ),
        ),
        const SizedBox(height: 20),

        // 제품명.
        Text('제품명',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(product.name, style: AppTextStyles.title),
        if (product.brand != null) ...[
          const SizedBox(height: 2),
          Text(product.brand!,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 20),

        // 대표성분 Top-3 (② top_ingredients) — 누르면 ① 해설.
        Text('대표성분',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (tops.isEmpty)
          Text('성분 정보가 아직 없어요',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tops)
                GestureDetector(
                  onTap: () => IngredientDetailSheet.show(
                    context,
                    ingredientId: t.ingredientId,
                    fallbackName: t.name,
                  ),
                  child: _chip(t.name ?? '성분 ${t.ingredientId}'),
                ),
            ],
          ),
        const SizedBox(height: 24),

        // 제품 해설 요약 (② summary). "주의:" 줄은 분리해 강조.
        _summaryBox(summary),
        const SizedBox(height: 24),

        // 권장 피부타입 — 대표성분을 BSTI 사전과 매칭한 결과 (프론트 계산).
        Text('권장 피부타입',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (matchedType != null)
          Row(
            children: [
              Text(matchedType.code,
                  style: AppTextStyles.pointLg(color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(matchedType.personaName,
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          )
        else
          Text('매칭되는 유형 정보가 없어요.',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 28),

        // 성분 목록 — 이름이 있는 대표성분은 행으로, 나머지는 개수로.
        Text('성분 자세히 보기',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final t in tops)
          _ingredientRow(context, t),
        if (insight.ingredientIds.length > tops.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              // TODO(BE): 전체 성분 이름 엔드포인트가 생기면 전부 나열한다.
              '외 ${insight.ingredientIds.length - tops.length}개 성분 분석됨',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  /// ② summary 박스. "확인 불가" / 주의 줄 / 본문을 구분해 그린다.
  Widget _summaryBox(ProductSummary summary) {
    if (summary.status == InsightStatus.unavailable ||
        summary.summary == null) {
      return PixelBox(
        borderColor: AppColors.outline,
        pixel: 6,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Text(
          '제품 해설이 아직 준비되지 않았어요.',
          style: AppTextStyles.body
              .copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      );
    }

    final split = splitCaution(summary.summary!);
    return PixelBox(
      borderColor: AppColors.primary,
      fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(split.body, style: AppTextStyles.body.copyWith(height: 1.6)),
          if (split.caution != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(split.caution!,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          height: 1.5)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => const Center(
        child: Icon(Icons.image_outlined, size: 48, color: AppColors.outline),
      );

  Widget _chip(String label) => PixelBox(
        borderColor: AppColors.primary,
        pixel: 5,
        borderWidth: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(label,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
      );

  Widget _ingredientRow(BuildContext context, TopIngredient t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () => IngredientDetailSheet.show(
            context,
            ingredientId: t.ingredientId,
            fallbackName: t.name,
          ),
          behavior: HitTestBehavior.opaque,
          child: PixelBox(
            borderColor: AppColors.outline,
            pixel: 5,
            borderWidth: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(t.name ?? '성분 ${t.ingredientId}',
                      style: AppTextStyles.body
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.expand_more,
                    color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      );
}
