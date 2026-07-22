import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../ingredient/data/ingredient_providers.dart';
import '../../ingredient/data/models/ingredient_insight.dart';
import 'models/product.dart';
import 'product_repository.dart';

/// 제품 저장소. 테스트에서는 이 프로바이더를 override 해서 가짜를 넣는다.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioProvider));
});

/// 제품 검색 결과. 검색어별로 캐시된다.
///
/// 빈 검색어는 네트워크를 타지 않는다.
final productSearchProvider =
    FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return const [];
  return ref.watch(productRepositoryProvider).search(query);
});

/// 특정 성분을 포함한 제품들 (성분 상세의 "이 성분이 든 제품").
final productsByIngredientProvider =
    FutureProvider.family<List<Product>, int>((ref, ingredientId) async {
  return ref.watch(productRepositoryProvider).getByIngredient(ingredientId);
});

/// 제품 상세에 필요한 서버 정보 묶음: 성분 id 목록 + ② 요약.
///
/// 명세 흐름: GET /products/{id}/ingredients → ids 를 **배합순 그대로**
/// POST /ingredients/product-summary 에 넘긴다 (앞 3개 = 대표성분).
final productInsightProvider = FutureProvider.family<
    ({List<int> ingredientIds, ProductSummary summary}), int>(
  (ref, productId) async {
    final ids =
        await ref.watch(productRepositoryProvider).getIngredientIds(productId);
    if (ids.isEmpty) {
      // 성분 정보가 없으면 요약도 요청하지 않는다 (② 는 성분이 없으면 404).
      return (
        ingredientIds: ids,
        summary: const ProductSummary(status: InsightStatus.unavailable),
      );
    }
    final summary =
        await ref.watch(ingredientRepositoryProvider).getProductSummary(ids);
    return (ingredientIds: ids, summary: summary);
  },
);
