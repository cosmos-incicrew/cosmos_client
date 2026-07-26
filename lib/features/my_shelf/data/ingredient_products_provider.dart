import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../product/data/models/product.dart';
import '../../product/data/product_providers.dart';
import '../../recommendation/data/recommendation_provider.dart';
import 'shelf_preference.dart';

/// 성분 → 그 성분이 든 제품 (프론트 도출).
///
/// 전용 역조회 API 가 없어서(TODO(BE): GET /ingredients/{id}/products),
/// **기존 API 만 조합**해 만든다:
///  1. 후보 풀 = 추천 씨앗 검색 제품(~40) + 내 화장대 제품
///  2. 제품별 성분 목록(/products/{id}/ingredients — family 캐시)과 대조
///  3. 해당 성분을 가진 제품만, 최대 5개
///
/// 성분 목록 조회는 추천·보고서와 캐시를 공유하므로 대부분 재사용이다.
final ingredientProductsProvider = FutureProvider.family<List<Product>,
    ({int id, String? nameKo})>((ref, ing) async {
  final ingredientId = ing.id;
  final pool = await ref.watch(recommendationPoolProvider.future);
  final shelf = ref.watch(shelfPreferenceProvider);

  final candidates = <int, Product>{};
  // 성분 이름이 제품명에 들어간 제품부터 (예: "글리세린 토너") — 적중률 최고.
  final nameKo = ing.nameKo?.trim();
  if (nameKo != null && nameKo.length >= 2) {
    try {
      final named =
          await ref.watch(productRepositoryProvider).search(nameKo);
      for (final p in named.take(10)) {
        candidates.putIfAbsent(p.id, () => p);
      }
    } on Object {
      // 검색 실패는 무시 — 풀 후보로 계속.
    }
  }
  for (final list in pool.byCategory.values) {
    for (final p in list) {
      candidates.putIfAbsent(p.id, () => p);
    }
  }
  for (final e in shelf) {
    if (e.isProduct) {
      candidates.putIfAbsent(e.id, () => Product(id: e.id, name: e.name));
    }
  }

  final checks = await Future.wait([
    for (final p in candidates.values)
      ref
          .watch(productIngredientIdsProvider(p.id).future)
          .then<Product?>((ids) => ids.contains(ingredientId) ? p : null)
          .catchError((_) => null),
  ]);
  return [
    for (final p in checks)
      if (p != null) p,
  ].take(5).toList();
});
