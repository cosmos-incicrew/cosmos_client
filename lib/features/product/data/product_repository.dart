import 'models/product.dart';

/// 제품 데이터 접근.
///
/// ⚠️ 아직 백엔드가 붙지 않아 전부 빈 결과를 돌려준다.
/// 백엔드 연동은 **이 클래스의 메서드 본문만** 바꾸면 끝난다 —
/// 화면·프로바이더는 손대지 않아도 된다.
///
/// 각 메서드의 `TODO(BE)` 주석에 필요한 엔드포인트와 응답 스키마를 적어두었다.
/// 전체 목록은 `grep -rn "TODO(BE)" lib/` 또는 [docs/api-contract.md] 참고.
class ProductRepository {
  const ProductRepository();

  /// 제품 검색 — 이름 또는 브랜드 부분일치(대소문자 무시).
  ///
  /// 빈 문자열이면 호출되지 않는다 (화면에서 막는다).
  ///
  /// TODO(BE): GET /products/search?q={query}
  ///   응답: [{"product_id": 1, "product_name": "...", "brand": "...",
  ///           "main_category": "스킨케어", "sub_category": "크림",
  ///           "ingredient_ids": [101, 102]}]
  ///   교체 예시:
  ///     final res = await _dio.get('/products/search',
  ///         queryParameters: {'q': query});
  ///     return (res.data as List)
  ///         .map((e) => Product.fromJson(e as Map<String, dynamic>))
  ///         .toList();
  Future<List<Product>> search(String query) async => const [];

  /// 전체 제품 — 추천 화면이 카테고리별로 묶어 쓴다.
  ///
  /// TODO(BE): GET /products
  ///   목록이 커지면 페이지네이션이 필요하다. 그 경우 이 메서드 대신
  ///   카테고리별 조회로 바꾸고 추천 프로바이더도 함께 수정할 것.
  Future<List<Product>> listAll() async => const [];

  /// 특정 성분을 포함한 제품들 — 성분 상세에서 "이 성분이 든 제품".
  ///
  /// TODO(BE): GET /ingredients/{ingredientId}/products
  Future<List<Product>> getByIngredient(int ingredientId) async => const [];

  /// 특정 BSTI 성분(예: 'niac')을 가진 제품 — 보고서의 "이 제품을 추천해요".
  ///
  /// [exclude] 는 이미 화장대에 담아 다시 추천하면 안 되는 제품 id.
  /// [limit] 개까지만 돌려준다.
  ///
  /// TODO(BE): GET /products?bsti_ingredient={bstiId}&limit={limit}
  ///   제품→성분→bsti_ingredient_id 조인이 필요하다.
  ///   [exclude] 는 응답이 적으므로 클라이언트에서 걸러도 되지만,
  ///   서버에서 처리하면 왕복이 준다.
  Future<List<Product>> findByBstiIngredient(
    String bstiId, {
    Set<int> exclude = const {},
    int limit = 2,
  }) async =>
      const [];
}
