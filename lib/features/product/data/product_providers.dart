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

/// 제품의 확정 성분 id (배합순). 상세 화면의 뼈대 — 이것만 있으면 그린다.
final productIngredientIdsProvider =
    FutureProvider.family<List<int>, int>((ref, productId) async {
  return ref.watch(productRepositoryProvider).getIngredientIds(productId);
});

/// ② 제품 요약 (LLM). **실패해도 상세 화면을 막지 않는다** —
/// 요약 칸만 "준비 안 됨"으로 뜨고 나머지는 정상.
final productSummaryProvider =
    FutureProvider.family<ProductSummary, int>((ref, productId) async {
  final ids = await ref.watch(productIngredientIdsProvider(productId).future);
  if (ids.isEmpty) {
    return const ProductSummary(status: InsightStatus.unavailable);
  }
  return ref.watch(ingredientRepositoryProvider).getProductSummary(ids);
});

/// 제품의 BSTI 성분 id — 권장/기피 타입·고민 매칭용 (프론트 계산).
final productBstiIdsProvider =
    FutureProvider.family<List<String>, int>((ref, productId) async {
  final map = await ref
      .watch(ingredientRepositoryProvider)
      .bstiIdsByProducts([productId]);
  return map[productId] ?? const [];
});
