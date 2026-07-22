import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import 'models/ingredient.dart';

/// 성분 데이터 접근 — cosmos_server `/api/v1/ingredients/*` 연동.
///
/// 모든 호출에 Supabase JWT가 필요하다 (dio 인터셉터가 자동 첨부).
/// `API_BASE_URL` 이 비어 있으면 호출하지 않고 빈 결과를 돌려준다.
///
/// ⚠️ 서버 필드명은 `name_kr` / `name_en` 이다 (프론트 모델의
/// `name_kor` / `name_eng` 와 다름). 여기서 명시적으로 매핑한다 —
/// Ingredient.fromJson 을 그대로 쓰면 조용히 null 로 파싱된다.
class IngredientRepository {
  const IngredientRepository(this._dio);

  final Dio _dio;

  /// 성분 검색 — 이명(한글·영문) 부분일치.
  ///
  /// GET /api/v1/ingredients/search?q={query}&limit=20
  /// 응답: {"query": "...", "results": [
  ///        {"ingredient_id", "name_kr", "name_en"}]}
  Future<List<Ingredient>> search(String query) async {
    if (!Env.hasApi || query.isEmpty) return const [];

    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/ingredients/search',
      queryParameters: {'q': query},
    );
    final results = (res.data?['results'] as List?) ?? const [];
    return [
      for (final raw in results.cast<Map<String, dynamic>>())
        Ingredient(
          id: raw['ingredient_id'] as int,
          nameKor: raw['name_kr'] as String?,
          // 모델의 nameEng 는 필수 — 영문명이 없으면 한글명으로 채운다.
          nameEng: (raw['name_en'] ?? raw['name_kr'] ?? '') as String,
        ),
    ];
  }

  /// id 목록으로 성분 조회 — 제품 상세의 성분 목록. **입력 순서 유지.**
  ///
  /// TODO(BE): 일괄 조회 엔드포인트가 서버에 없다.
  ///   있는 것: GET /api/v1/ingredients/{id}/detail (LLM 해설 — 목록용으로는 무거움)
  ///           POST /api/v1/ingredients/product-summary (대표성분+요약 —
  ///           제품 상세를 이쪽으로 개편하는 게 서버 설계와 맞다)
  ///   제안: GET /api/v1/ingredients?ids=101,102 (배열 순서 = 요청 순서)
  Future<List<Ingredient>> getByIds(List<int> ids) async => const [];

  /// 제품들이 가진 BSTI 성분 id — 보고서 적합도 계산용 (배치).
  ///
  /// TODO(BE): 서버 DB에 bsti_ingredient_id 매핑 자체가 없다
  ///   (ingredients 테이블: ingredient_id·name_kr·name_en·cas_no… 뿐).
  ///   보고서의 적합도 점수·부족 성분 추천이 전부 이 매핑에 걸려 있으므로,
  ///   매핑 추가를 백엔드에 요청해야 한다. 그 전까지 빈 결과 유지
  ///   (보고서는 "판단 정보 부족"으로 표시된다 — 지어내지 않는다).
  Future<Map<int, List<String>>> bstiIdsByProducts(
    List<int> productIds,
  ) async =>
      const {};
}
