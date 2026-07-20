import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bsti/bsti.dart';
import '../../bsti/bsti_result_store.dart';
import '../../ingredient/data/ingredient_providers.dart';
import '../../my_shelf/data/shelf_preference.dart';
import '../../onboarding/data/profile_store.dart';
import '../../product/data/models/product.dart';
import '../../product/data/product_providers.dart';

/// 추천 근거 — 화면 상단에 "무엇을 반영했는지" 그대로 보여준다.
///
/// 반영한 것만 담는다. BSTI를 안 했으면 [typeCode] 가 null 이고,
/// 화면도 그 말을 하지 않는다.
class RecommendationBasis {
  const RecommendationBasis({
    required this.typeCode,
    required this.concernLabels,
    required this.avoidCount,
  });

  final String? typeCode;
  final List<String> concernLabels;
  final int avoidCount;

  bool get isEmpty =>
      typeCode == null && concernLabels.isEmpty && avoidCount == 0;
}

/// 카테고리별 추천 결과 + 근거.
class RecommendationResult {
  const RecommendationResult({required this.byCategory, required this.basis});

  /// 소분류(토너·크림…) → 제품들. 나에게 맞는 순으로 정렬돼 있다.
  final Map<String, List<Product>> byCategory;
  final RecommendationBasis basis;
}

/// 맞춤 추천 — 내 피부유형 + 피부고민 + 기피성분을 반영한다.
///
/// 점수를 지어내지 않는다. "내가 찾는 성분과 몇 개나 겹치는가"로만 정렬한다.
final recommendationProvider =
    FutureProvider<RecommendationResult>((ref) async {
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

  final basis = RecommendationBasis(
    typeCode: typeCode,
    concernLabels: profile.concerns.map((c) => c.label).toList(),
    avoidCount: avoidIngredientIds.length,
  );

  final products = await ref.watch(productRepositoryProvider).listAll();
  if (products.isEmpty) {
    return RecommendationResult(byCategory: const {}, basis: basis);
  }

  // 내가 찾는 BSTI 성분 = 내 유형 권장 + 내 고민에 맞는 성분.
  final wanted = <String>{
    ...?kBstiSkinTypes[typeCode]?.recommend.map((e) => e.ingredientId),
    for (final c in profile.concerns) ...?kConcernIngredients[c],
  };

  // 제품들이 쓰는 성분을 한 번에 받아 id→BSTI id 맵을 만든다.
  // (예전에는 정렬 비교자 안에서 성분을 매번 선형 탐색해 O(n²)였다)
  final bstiByProduct = await ref
      .watch(ingredientRepositoryProvider)
      .bstiIdsByProducts(products.map((p) => p.id).toList());

  // 기피 제품·성분을 걸러 카테고리별로 묶는다.
  final map = <String, List<_Scored>>{};
  for (final p in products) {
    final category = p.subCategory;
    if (category == null) continue;
    if (avoidProductIds.contains(p.id)) continue;
    if (p.ingredientIds.any(avoidIngredientIds.contains)) continue;

    // hit 수를 제품당 한 번만 계산한다 (정렬 중 재계산 없음).
    final hits = wanted.isEmpty
        ? 0
        : (bstiByProduct[p.id] ?? const [])
            .where(wanted.contains)
            .length;
    map.putIfAbsent(category, () => []).add(_Scored(p, hits));
  }

  // 맞는 성분이 많은 제품부터. (동점이면 원래 순서 유지 — 안정 정렬)
  final byCategory = <String, List<Product>>{};
  for (final entry in map.entries) {
    final list = entry.value;
    if (wanted.isNotEmpty) {
      list.sort((a, b) => b.hits.compareTo(a.hits));
    }
    byCategory[entry.key] = [for (final s in list) s.product];
  }
  return RecommendationResult(byCategory: byCategory, basis: basis);
});

/// 정렬용 (제품, 겹치는 성분 수) 쌍.
class _Scored {
  const _Scored(this.product, this.hits);
  final Product product;
  final int hits;
}
