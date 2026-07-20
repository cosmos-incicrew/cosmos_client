import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/mock/mock_data.dart';
import '../../bsti/bsti.dart';
import '../../bsti/bsti_result_store.dart';
import '../../my_shelf/data/shelf_preference.dart';
import '../../product/data/models/product.dart';
import 'report_engine.dart';

/// 제품 id → 그 제품이 가진 BSTI 성분 id 목록.
///
/// ⚠️ 지금은 목데이터에서 찾는다. (mockProducts → mockIngredients)
/// 백엔드가 붙으면 이 함수만 API 조회로 바꾸면 되고,
/// [ReportEngine] 은 목데이터를 전혀 모르므로 그대로 둔다.
List<String> _bstiIngredientIdsOf(int productId) {
  final product = mockProducts.where((p) => p.id == productId).firstOrNull;
  if (product == null) return const [];

  final ids = <String>[];
  for (final ingredientId in product.ingredientIds) {
    final ing =
        mockIngredients.where((i) => i.id == ingredientId).firstOrNull;
    final bstiId = ing?.bstiIngredientId;
    if (bstiId != null) ids.add(bstiId);
  }
  return ids;
}

/// 화장대 종합 보고서 — 내 BSTI 유형 + 담은 제품으로 계산된다.
///
/// 검사를 다시 하거나 제품을 담으면 자동으로 다시 계산된다.
final shelfReportProvider = Provider<ShelfReport>((ref) {
  final typeCode = ref.watch(bstiResultProvider);
  final entries = ref.watch(shelfPreferenceProvider);

  return ReportEngine.build(
    typeCode: typeCode,
    entries: entries,
    ingredientIdsOf: _bstiIngredientIdsOf,
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
/// ⚠️ 목데이터 기반. 부족 성분(권장인데 화장대에 없는 것) 중 위에서부터
/// 최대 3개를 골라, 그 성분을 가진 목 제품을 붙인다.
/// 이미 화장대에 담은 제품과 추천할 제품이 없는 성분은 제외한다.
final shelfSuggestionsProvider = Provider<List<ShelfSuggestion>>((ref) {
  final report = ref.watch(shelfReportProvider);
  final entries = ref.watch(shelfPreferenceProvider);

  // 이미 담은 제품은 다시 추천하지 않는다.
  final ownedProductIds =
      entries.where((e) => e.isProduct).map((e) => e.id).toSet();

  final suggestions = <ShelfSuggestion>[];
  for (final bstiId in report.missingIngredientIds) {
    final info = kBstiIngredients[bstiId];
    if (info == null) continue;

    // 이 BSTI 성분을 담고 있는 목 제품 찾기.
    final products = <Product>[];
    for (final p in mockProducts) {
      if (ownedProductIds.contains(p.id)) continue;
      final has = p.ingredientIds.any((id) {
        final ing = mockIngredients.where((i) => i.id == id).firstOrNull;
        return ing?.bstiIngredientId == bstiId;
      });
      if (has) products.add(p);
      if (products.length == 2) break; // 성분당 최대 2개만
    }

    // 추천할 제품이 없으면 "부족합니다"만 띄우지 않는다 (행동할 수 없는 안내라서).
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
