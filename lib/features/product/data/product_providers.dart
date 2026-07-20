import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/product.dart';
import 'product_repository.dart';

/// 제품 저장소. 테스트에서는 이 프로바이더를 override 해서 가짜를 넣는다.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return const ProductRepository();
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
