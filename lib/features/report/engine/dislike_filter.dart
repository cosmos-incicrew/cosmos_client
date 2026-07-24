/// 기피 성분 필터 — 사용자가 화장대에서 "기피"로 담은 성분은
/// 추천(성분·제품)에서 걸러낸다. 순수 함수, 서버 무관.
///
/// 이름 기준 정확 일치로 거른다 (BSTI 매칭과 같은 원칙 — 애매한 매칭으로
/// 멀쩡한 추천을 지우지 않는다).
library;

import '../data/recommendation.dart';

abstract final class DislikeFilter {
  /// 추천 성분 목록에서 기피 성분을 제외한다.
  static List<RecoIngredient> ingredients(
    List<RecoIngredient> items,
    Set<String> dislikedNames,
  ) {
    if (dislikedNames.isEmpty) return items;
    return [
      for (final i in items)
        if (!dislikedNames.contains(i.nameKor)) i,
    ];
  }

  /// 추천 제품 목록에서 기피 성분 때문에 추천된 제품을 정리한다.
  ///
  /// 제품의 매칭 성분 중 기피 성분을 지우고, **남는 매칭 근거가 없으면
  /// 제품 자체를 제외**한다 (기피 성분 하나 때문에 추천된 제품이므로).
  static List<RecoProduct> products(
    List<RecoProduct> items,
    Set<String> dislikedNames,
  ) {
    if (dislikedNames.isEmpty) return items;
    final out = <RecoProduct>[];
    for (final p in items) {
      final kept = [
        for (final n in p.matchedIngredients)
          if (!dislikedNames.contains(n)) n,
      ];
      if (kept.isEmpty && p.matchedIngredients.isNotEmpty) continue;
      out.add(RecoProduct(
        productId: p.productId,
        productName: p.productName,
        brand: p.brand,
        productUrl: p.productUrl,
        mainCategory: p.mainCategory,
        matchedIngredients: kept,
      ));
    }
    return out;
  }
}
