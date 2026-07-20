import 'models/ingredient.dart';

/// 성분 데이터 접근.
///
/// ⚠️ 아직 백엔드가 붙지 않아 전부 빈 결과를 돌려준다.
/// 백엔드 연동은 **이 클래스의 메서드 본문만** 바꾸면 끝난다.
///
/// 각 메서드의 `TODO(BE)` 주석에 필요한 엔드포인트와 응답 스키마를 적어두었다.
/// 전체 목록은 `grep -rn "TODO(BE)" lib/` 또는 [docs/api-contract.md] 참고.
class IngredientRepository {
  const IngredientRepository();

  /// 성분 검색 — 한글명 또는 영문명 부분일치(대소문자 무시).
  ///
  /// TODO(BE): GET /ingredients/search?q={query}
  ///   응답: [{"ingredient_id": 101, "name_kor": "글리세린",
  ///           "name_eng": "Glycerin", "efficacy": "...",
  ///           "recommended_skin_type": "모든 피부",
  ///           "bsti_ingredient_id": "gly"}]
  Future<List<Ingredient>> search(String query) async => const [];

  /// id 목록으로 성분 조회 — 제품 상세의 성분 목록.
  ///
  /// ⚠️ **입력 [ids] 순서를 그대로 유지해야 한다.**
  /// 제품 상세가 앞에서 3개를 잘라 "대표성분"으로 보여주기 때문에,
  /// 순서가 바뀌면 대표성분이 조용히 달라진다.
  /// SQL `WHERE id IN (...)` 는 순서를 보장하지 않으므로,
  /// 서버에서 정렬하거나 클라이언트에서 [ids] 기준으로 다시 정렬할 것.
  /// 없는 id는 그냥 빠진다 (에러 아님).
  ///
  /// TODO(BE): GET /ingredients?ids=101,102,103
  Future<List<Ingredient>> getByIds(List<int> ids) async => const [];

  /// 제품들이 가진 BSTI 성분 id — 보고서 적합도 계산용.
  ///
  /// 반환: `{제품 id: [BSTI 성분 id, ...]}`
  /// 제품마다 한 번씩 부르지 않도록 **배치로** 받는다.
  ///
  /// TODO(BE): GET /products/bsti-ingredients?product_ids=1,2,3
  ///   응답: {"1": ["cera", "gly"], "2": ["niac"]}
  ///   bsti_ingredient_id 가 없는 성분은 제외한다.
  Future<Map<int, List<String>>> bstiIdsByProducts(
    List<int> productIds,
  ) async =>
      const {};
}
