import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/mock/mock_data.dart';
import '../../../../core/widgets/pixel_box.dart';
import '../../../bsti/bsti.dart';
import '../../../bsti/bsti_result_store.dart';
import '../../../my_shelf/data/shelf_preference.dart';
import '../../../my_shelf/presentation/screens/product_detail_screen.dart';
import '../../../onboarding/data/profile_store.dart';
import '../../../onboarding/data/skin_concern.dart';
import '../../../product/data/models/product.dart';

/// 맞춤 제품 추천 — 카테고리(토너·크림·선크림…)별로 나눠 보여준다.
///
/// ⚠️ 지금은 목데이터(mockProducts) 기반 데모다. 카테고리로만 묶어 보여주고
/// 개인화 점수는 매기지 않는다. 서버 recommendation 모듈(근거 기반 생성)이
/// 붙으면 [_byCategory] 를 API 결과로 갈아끼우면 된다. 서버 규칙상 근거가
/// 부족하면 "확인 불가"를 내야 하므로, 문구도 단정 대신 "추천" 수준으로 둔다.
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
    final typeCode = ref.watch(bstiResultProvider);
    final profile = ref.watch(userProfileProvider);
    final shelf = ref.watch(shelfPreferenceProvider);

    // 화장대에서 "기피"로 담은 성분·제품은 추천에서 뺀다.
    final avoidIngredientIds = shelf
        .where((e) => !e.isProduct && e.kind == PreferenceKind.dislike)
        .map((e) => e.id)
        .toSet();
    final avoidProductIds = shelf
        .where((e) => e.isProduct && e.kind == PreferenceKind.dislike)
        .map((e) => e.id)
        .toSet();

    final grouped = _byCategory(
      typeCode: typeCode,
      concerns: profile.concerns,
      avoidIngredientIds: avoidIngredientIds,
      avoidProductIds: avoidProductIds,
    );

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            _header(typeCode, profile, avoidIngredientIds.length),
            const SizedBox(height: 24),
            for (final category in _categoryOrder)
              if (grouped[category] != null && grouped[category]!.isNotEmpty)
                _categorySection(context, category, grouped[category]!),
          ],
        ),
      ),
    );
  }

  /// 상단 안내 — 무엇을 반영해 추천했는지 근거를 밝힌다.
  ///
  /// 반영한 것만 적는다. BSTI를 안 했으면 "BSTI 반영"이라고 쓰지 않는다.
  Widget _header(String? typeCode, UserProfile profile, int avoidCount) {
    final basis = <String>[
      if (typeCode != null) '내 피부유형($typeCode)',
      if (profile.hasConcerns)
        '피부고민(${profile.concerns.map((c) => c.label).join('·')})',
      if (avoidCount > 0) '기피성분 $avoidCount개',
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
                    const SizedBox(height: 6),
                    // 이 제품의 주요 성분 — 무엇 때문에 뜬 건지 보이게.
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final name in keyIngredientNames(p))
                          _ingredientChip(name),
                      ],
                    ),
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

  /// 목 제품을 subCategory 별로 묶는다.
  ///
  /// 기피로 담은 제품·성분은 빼고, 내 유형·고민에 맞는 성분을 가진 제품을
  /// 앞으로 올린다. (점수를 지어내지 않고 "겹치는 성분 개수"로만 정렬한다)
  Map<String, List<Product>> _byCategory({
    required String? typeCode,
    required Set<SkinConcern> concerns,
    required Set<int> avoidIngredientIds,
    required Set<int> avoidProductIds,
  }) {
    // 내가 찾는 BSTI 성분 = 내 유형 권장 + 내 고민에 맞는 성분.
    final wanted = <String>{
      ...?kBstiSkinTypes[typeCode]?.recommend.map((e) => e.ingredientId),
      for (final c in concerns) ...?kConcernIngredients[c],
    };

    final map = <String, List<Product>>{};
    for (final p in mockProducts) {
      final key = p.subCategory;
      if (key == null) continue;
      // 기피로 담은 제품은 추천하지 않는다.
      if (avoidProductIds.contains(p.id)) continue;
      // 기피 성분이 든 제품도 빼준다.
      if (p.ingredientIds.any(avoidIngredientIds.contains)) continue;
      map.putIfAbsent(key, () => []).add(p);
    }

    // 나에게 맞는 성분을 많이 가진 제품부터.
    if (wanted.isNotEmpty) {
      for (final list in map.values) {
        list.sort((a, b) => _hits(b, wanted).compareTo(_hits(a, wanted)));
      }
    }
    return map;
  }

  /// 제품이 가진 성분 중 [wanted](BSTI id)와 겹치는 개수.
  static int _hits(Product p, Set<String> wanted) {
    var n = 0;
    for (final id in p.ingredientIds) {
      final ing = mockIngredients.where((i) => i.id == id).firstOrNull;
      final bstiId = ing?.bstiIngredientId;
      if (bstiId != null && wanted.contains(bstiId)) n++;
    }
    return n;
  }
}

/// 제품의 성분 id를 이름으로 바꿔 최대 [max]개까지.
/// (추천 화면·보고서에서 같이 쓴다)
List<String> keyIngredientNames(Product p, {int max = 3}) {
  final names = <String>[];
  for (final id in p.ingredientIds) {
    final match = mockIngredients.where((i) => i.id == id);
    if (match.isEmpty) continue;
    names.add(match.first.displayName);
    if (names.length == max) break;
  }
  return names;
}
