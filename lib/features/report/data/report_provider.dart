import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bsti/bsti.dart';
import '../../bsti/bsti_result_store.dart';
import '../../ingredient/data/ingredient_providers.dart';
import '../../my_shelf/data/shelf_preference.dart';
import '../../product/data/models/product.dart';
import '../../product/data/product_providers.dart';
import 'report_engine.dart';

/// 화장대 종합 보고서 — 내 BSTI 유형 + 담은 제품으로 계산된다.
///
/// 검사를 다시 하거나 제품을 담으면 자동으로 다시 계산된다.
///
/// 설계 메모: [ReportEngine] 은 **동기 순수 함수로 유지한다.**
/// 성분 조회를 엔진 안으로 넣으면 제품마다 순차 왕복이 생기고,
/// 검증된 도메인 로직이 네트워크에 묶인다. 대신 여기서 성분 맵을
/// 한 번에(배치) 받아둔 뒤, 엔진에는 동기 콜백으로 넘긴다.
final shelfReportProvider = FutureProvider<ShelfReport>((ref) async {
  final typeCode = ref.watch(bstiResultProvider);
  final entries = ref.watch(shelfPreferenceProvider);

  final productIds =
      entries.where((e) => e.isProduct).map((e) => e.id).toList();

  // 담은 제품들의 BSTI 성분을 배치로 1회 조회.
  final byProduct = productIds.isEmpty
      ? const <int, List<String>>{}
      : await ref
          .watch(ingredientRepositoryProvider)
          .bstiIdsByProducts(productIds);

  return ReportEngine.build(
    typeCode: typeCode,
    entries: entries,
    // 이미 받아둔 맵을 읽기만 하므로 여전히 동기 — 엔진 시그니처 그대로.
    ingredientIdsOf: (id) => byProduct[id] ?? const [],
  );
});

/// 부족한 성분 하나 + 그 성분을 채워주는 추천 제품.
class ShelfSuggestion {
  const ShelfSuggestion({
    required this.ingredientName,
    required this.ingredientRole,
    required this.products,
  });

  /// 부족한 성분 이름 (예: '세라마이드').
  final String ingredientName;

  /// 그 성분이 하는 일 (예: '장벽 복구·경피수분손실 감소'). 데이터에 없으면 null.
  final String? ingredientRole;

  /// 이 성분을 가진 제품들 (이미 담은 건 빠진다).
  final List<Product> products;
}

/// 보고서 하단 "OO 성분이 부족합니다 → 이 제품을 추천해요".
///
/// 부족 성분(내 유형 권장인데 화장대에 없는 것) 중 위에서부터 최대 3개를 골라,
/// 그 성분을 가진 제품을 붙인다. 이미 담은 제품은 제외한다.
/// **추천할 제품이 없는 성분은 아예 넣지 않는다** — 행동할 수 없는 안내라서.
final shelfSuggestionsProvider =
    FutureProvider<List<ShelfSuggestion>>((ref) async {
  final report = await ref.watch(shelfReportProvider.future);
  final entries = ref.watch(shelfPreferenceProvider);
  final repo = ref.watch(productRepositoryProvider);

  // 이미 담은 제품은 다시 추천하지 않는다.
  final ownedProductIds =
      entries.where((e) => e.isProduct).map((e) => e.id).toSet();

  final suggestions = <ShelfSuggestion>[];
  for (final bstiId in report.missingIngredientIds) {
    final info = kBstiIngredients[bstiId];
    if (info == null) continue;

    final products = await repo.findByBstiIngredient(
      bstiId,
      exclude: ownedProductIds,
      limit: 2, // 성분당 최대 2개
    );
    if (products.isEmpty) continue;

    suggestions.add(ShelfSuggestion(
      ingredientName: info.nameKo,
      ingredientRole: info.role,
      products: products,
    ));
    if (suggestions.length == 3) break; // 화면엔 최대 3개
  }
  return suggestions;
});
