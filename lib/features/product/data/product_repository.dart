import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import 'models/product.dart';

/// 제품 데이터 접근 — cosmos_server `/api/v1/products/*` 연동.
///
/// 모든 호출에 Supabase JWT가 필요하다 (dio 인터셉터가 자동 첨부).
/// `API_BASE_URL` 이 비어 있으면 호출하지 않고 빈 결과를 돌려준다.
///
/// 아직 백엔드에 없는 엔드포인트는 `TODO(BE)` 로 남겨두었다.
/// 전체 계약은 [docs/api-contract.md] 참고.
class ProductRepository {
  const ProductRepository(this._dio);

  final Dio _dio;

  /// 제품 검색 — 제품명 부분일치.
  ///
  /// GET /api/v1/products/search?q={query}&limit=20
  /// 응답: {"query": "...", "results": [{"id", "product_name", "brand",
  ///        "main_category", "sub_category", "detailed_category", "product_url"}]}
  ///
  /// ⚠️ 검색 응답에는 ingredient_ids 가 없다 — 필요하면
  /// [getIngredientIds] 로 따로 받는다 (백엔드가 2단계로 설계함).
  Future<List<Product>> search(String query) async {
    if (!Env.hasApi || query.isEmpty) return const [];

    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/products/search',
      queryParameters: {'q': query},
    );
    final results = (res.data?['results'] as List?) ?? const [];
    return [
      for (final raw in results.cast<Map<String, dynamic>>())
        Product(
          id: raw['id'] as int,
          name: raw['product_name'] as String,
          brand: raw['brand'] as String?,
          mainCategory: raw['main_category'] as String?,
          subCategory: raw['sub_category'] as String?,
          productUrl: raw['product_url'] as String?,
        ),
    ];
  }

  /// 제품의 확정 성분 id 목록 (배합 순서).
  ///
  /// GET /api/v1/products/{id}/ingredients
  /// 응답: {"id", "product_name", "ingredient_ids": [...],
  ///        "mapped_ingredient_count", "unmapped_ingredient_count",
  ///        "restricted_ingredients": [...]}
  ///
  /// 404 PRODUCT_NOT_FOUND / 422 PRODUCT_NOT_ANALYZABLE 이 올 수 있다.
  Future<List<int>> getIngredientIds(int productId) async {
    if (!Env.hasApi) return const [];

    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/products/$productId/ingredients',
    );
    return ((res.data?['ingredient_ids'] as List?) ?? const []).cast<int>();
  }

  /// 전체 제품 — 추천 화면이 카테고리별로 묶어 쓴다.
  ///
  /// TODO(BE): 전체 목록 엔드포인트가 서버에 없다.
  ///   실제 추천은 POST /api/v1/recommendations (RAG 파이프라인)로 가는 게
  ///   맞고, 그 응답은 성분 중심이라 추천 화면 개편이 함께 필요하다.
  ///   백엔드 담당과 협의 전까지 빈 결과 유지.
  Future<List<Product>> listAll() async => const [];

  /// 특정 성분을 포함한 제품들 — 성분 상세에서 "이 성분이 든 제품".
  ///
  /// TODO(BE): 성분→제품 역조회 엔드포인트가 서버에 없다.
  ///   제안: GET /api/v1/ingredients/{ingredientId}/products
  Future<List<Product>> getByIngredient(int ingredientId) async => const [];

  /// 특정 BSTI 성분(예: 'niac')을 가진 제품 — 보고서의 "이 제품을 추천해요".
  ///
  /// TODO(BE): 서버 DB에 bsti_ingredient_id 매핑 자체가 없다
  ///   (supabase/migrations/001_create_ingredients.sql 참고).
  ///   매핑 컬럼(또는 매핑 테이블) 추가를 백엔드에 요청해야 한다.
  Future<List<Product>> findByBstiIngredient(
    String bstiId, {
    Set<int> exclude = const {},
    int limit = 2,
  }) async =>
      const [];
}
