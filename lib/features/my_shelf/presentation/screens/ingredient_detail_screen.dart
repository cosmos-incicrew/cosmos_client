import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../bsti/bsti.dart';
import '../../../ingredient/data/models/ingredient.dart';
import '../../../product/data/models/product.dart';
import '../../../product/data/product_providers.dart';
import 'product_detail_screen.dart';

/// 성분 상세 화면 (검색 결과에서 성분 진입).
///
/// 시안 구성: 검색 성분(칩) → 역할·특징 요약(박스) → 권장 피부타입(코드+페르소나) →
/// 성분 포함 제품. 포함 제품은 저장소에서 역조회한다.
class IngredientDetailScreen extends ConsumerWidget {
  const IngredientDetailScreen({super.key, required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 이 성분을 포함하는 제품 (이 목록만 비동기 — 나머지는 바로 그린다).
    final productsAsync =
        ref.watch(productsByIngredientProvider(ingredient.id));
    // 이 성분을 권장 성분으로 가진 BSTI 유형을 실제 데이터로 매칭.
    final type = ingredient.bstiIngredientId == null
        ? null
        : BstiEngine.matchTypeByIngredients([ingredient.bstiIngredientId!]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('성분 상세', style: AppTextStyles.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        children: [
          // 검색 성분 — 박스 없이 큰 글씨로.
          Text('검색 성분',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text(
            ingredient.nameKor != null
                ? '${ingredient.nameKor} (${ingredient.nameEng})'
                : ingredient.nameEng,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            style: AppTextStyles.title.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 16),

          // 역할·특징 요약(박스).
          PixelBox(
            borderColor: AppColors.primary,
            fillColor: AppColors.primaryLight.withValues(alpha: 0.35),
            pixel: 6,
            borderWidth: 2.5,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Text(
              ingredient.efficacy ?? '성분 정보가 준비 중이에요.',
              style: AppTextStyles.body.copyWith(height: 1.5),
            ),
          ),
          const SizedBox(height: 28),

          // 권장 피부타입 (코드 + 페르소나).
          Text('권장 피부타입',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (type != null) ...[
            Text(type.code,
                style: AppTextStyles.pointLg(color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(type.personaName,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ] else
            Text(ingredient.recommendedSkinType ?? '모든 피부',
                style: AppTextStyles.title),
          const SizedBox(height: 28),

          // 성분 포함 제품.
          Text('성분 포함 제품',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          // 로딩·실패·없음을 구분해서 보여준다.
          ...productsAsync.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, __) => [
              Text('제품 정보를 불러오지 못했어요',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
            data: (products) => products.isEmpty
                ? [
                    Text('등록된 제품이 없어요.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ]
                : [
                    for (final p in products) _productCard(context, p),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, Product p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: p),
          ));
        },
        behavior: HitTestBehavior.opaque,
        child: PixelBox(
          borderColor: AppColors.outline,
          pixel: 5,
          borderWidth: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // 제품 이미지 (없으면 플레이스홀더).
              Container(
                width: 44,
                height: 44,
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                child: p.imageAsset != null
                    ? Image.asset(p.imageAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_outlined,
                            size: 22,
                            color: AppColors.outline))
                    : const Icon(Icons.image_outlined,
                        size: 22, color: AppColors.outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${p.brand ?? ''} · ${p.subCategory ?? ''}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
