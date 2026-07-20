import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../my_shelf/presentation/screens/product_detail_screen.dart';
import '../../../product/data/models/product.dart';
import '../../data/recommendation_provider.dart';

/// 맞춤 제품 추천 — 카테고리(토너·크림·선크림…)별로 나눠 보여준다.
///
/// 계산은 [recommendationProvider] 가 한다 (내 피부유형·피부고민·기피성분 반영).
/// 이 화면은 그 결과를 그리기만 한다.
/// 서버 규칙상 근거가 부족하면 "확인 불가"를 내야 하므로,
/// 문구도 단정 대신 "추천" 수준으로 둔다.
class RecommendationScreen extends ConsumerWidget {
  const RecommendationScreen({super.key});

  /// 화면에 보일 카테고리 순서 (스킨케어 사용 순서대로).
  static const _categoryOrder = <String>[
    '토너',
    '세럼/앰플',
    '에센스',
    '로션',
    '크림',
    '선크림',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('맞춤 추천', style: AppTextStyles.title),
      ),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _message('추천을 불러오지 못했어요'),
          data: (result) => _body(context, result),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RecommendationResult result) {
    final grouped = result.byCategory;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      children: [
        _header(result.basis),
        const SizedBox(height: 24),
        if (grouped.isEmpty)
          _message('추천할 제품을 찾지 못했어요')
        else
          for (final category in _categoryOrder)
            if (grouped[category] != null && grouped[category]!.isNotEmpty)
              _categorySection(context, category, grouped[category]!),
      ],
    );
  }

  Widget _message(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTextStyles.body
                  .copyWith(color: AppColors.textSecondary)),
        ),
      );

  /// 상단 안내 — 무엇을 반영해 추천했는지 근거를 밝힌다.
  ///
  /// 반영한 것만 적는다. BSTI를 안 했으면 "BSTI 반영"이라고 쓰지 않는다.
  Widget _header(RecommendationBasis basisData) {
    final basis = <String>[
      if (basisData.typeCode != null) '내 피부유형(${basisData.typeCode})',
      if (basisData.concernLabels.isNotEmpty)
        '피부고민(${basisData.concernLabels.join('·')})',
      if (basisData.avoidCount > 0) '기피성분 ${basisData.avoidCount}개',
    ];

    final text = basis.isEmpty
        ? 'BSTI 검사와 프로필을 입력하면 나에게 맞는 추천을 받을 수 있어요'
        : '${basis.join(', ')}을(를) 반영해 추천했어요';

    return PixelBox(
      borderColor: AppColors.primary,
      fillColor: AppColors.primaryLight,
      pixel: 6,
      borderWidth: 2.5,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome,
              color: AppColors.primaryDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.primaryDark, height: 1.5)),
          ),
        ],
      ),
    );
  }

  /// 한 카테고리 (예: 크림) + 그 안의 제품들.
  Widget _categorySection(
      BuildContext context, String category, List<Product> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(category,
                  style: AppTextStyles.pointSm(color: AppColors.textPrimary)),
              const SizedBox(width: 8),
              Text('${items.length}개',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in items) _productCard(context, p),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: AppTextStyles.body
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(p.brand ?? '',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    if (p.subCategory != null) ...[
                      const SizedBox(height: 6),
                      _ingredientChip(p.subCategory!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ingredientChip(String name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(name,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.primaryDark, fontSize: 11)),
      );

}
