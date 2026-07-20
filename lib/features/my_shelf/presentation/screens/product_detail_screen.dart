import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../bsti/bsti.dart';
import '../../../ingredient/data/models/ingredient.dart';
import '../../../product/data/models/product.dart';

/// 제품 상세 화면 (검색 결과에서 진입).
///
/// 시안 구성: 제품 이미지 → 제품명 → 대표성분(칩) → 권장 피부타입 요약 →
/// 성분 자세히 보기. 성분은 [Product.ingredientIds]로 [mockIngredients]에서 조회.
class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  List<Ingredient> get _ingredients => [
        for (final id in product.ingredientIds)
          for (final ing in mockIngredients)
            if (ing.id == id) ing,
      ];

  @override
  Widget build(BuildContext context) {
    final ingredients = _ingredients;
    // 대표성분 = 앞 3개.
    final key = ingredients.take(3).toList();
    // 성분들을 BSTI 성분 id로 변환 → 실제 권장 유형 매칭.
    final bstiIds =
        ingredients.map((i) => i.bstiIngredientId).whereType<String>();
    final matchedType = BstiEngine.matchTypeByIngredients(bstiIds);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('제품 상세', style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
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
              // 로컬 에셋 우선 → 없으면 네트워크 → 둘 다 없으면 플레이스홀더.
              child: product.imageAsset != null
                  ? Image.asset(product.imageAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                  : product.imageUrl != null
                      ? Image.network(product.imageUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
            ),
          ),
          const SizedBox(height: 20),

          // 제품명.
          Text('제품명',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(product.name, style: AppTextStyles.title),
          if (product.brand != null) ...[
            const SizedBox(height: 2),
            Text(product.brand!,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 20),

          // 대표성분 (칩).
          Text('대표성분',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in key) _chip(i.displayName),
            ],
          ),
          const SizedBox(height: 24),

          // 요약 박스.
          PixelBox(
            borderColor: AppColors.primary,
            fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
            pixel: 6,
            borderWidth: 2.5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: SizedBox(
              width: double.infinity,
              child: Text(
                _summary(key),
                style: AppTextStyles.body.copyWith(height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 권장 피부타입 — 성분 구성으로 실제 매칭한 BSTI 유형(코드+페르소나).
          Text('권장 피부타입',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (matchedType != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
            ),
          ] else
            Text('매칭되는 유형 정보가 없어요.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 28),

          // 성분 자세히 보기.
          Text('성분 자세히 보기',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final i in ingredients) _ingredientRow(i),
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
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textPrimary)),
      );

  String _summary(List<Ingredient> key) {
    if (key.isEmpty) return '등록된 성분 정보가 없어요.';
    final types = key
        .map((i) => i.recommendedSkinType)
        .whereType<String>()
        .toSet()
        .join(', ');
    final names = key.map((i) => i.displayName).join(', ');
    // 강제 줄바꿈 없이 한 문단으로 (넘치면 자연 줄바꿈).
    final base = '$names 등이 함유된 제품이에요.';
    return types.isEmpty ? base : '$base $types 피부에 잘 맞습니다.';
  }

  Widget _ingredientRow(Ingredient i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: PixelBox(
          borderColor: AppColors.outline,
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(i.displayName,
                  style: AppTextStyles.body
                      .copyWith(fontWeight: FontWeight.w700)),
              if (i.efficacy != null) ...[
                const SizedBox(height: 4),
                Text(i.efficacy!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary, height: 1.4)),
              ],
            ],
          ),
        ),
      );
}
