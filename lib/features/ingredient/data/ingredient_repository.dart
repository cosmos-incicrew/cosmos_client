import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../bsti/bsti.dart';
import '../../bsti/bsti_name_matcher.dart';
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
  IngredientRepository(this._dio);

  final Dio _dio;

  /// 서버 성분 id → BSTI 성분 id 인덱스 (앱 실행 동안 캐시).
  ///
  /// 서버 DB에 매핑이 없어 프론트가 이름으로 잇는다 — BSTI 는 프론트 완결.
  Map<int, String>? _bstiIndex;

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
  /// BSTI 는 프론트 완결이다. 서버 DB에 매핑이 없으므로:
  ///  1. BSTI 사전 34개를 서버 검색으로 찾아 `서버 id → BSTI id` 인덱스 구성
  ///     (한글명·INCI **정확 일치**만 인정 — 앱 실행 동안 캐시)
  ///  2. 제품마다 GET /api/v1/products/{id}/ingredients 로 성분 id 를 받아
  ///     인덱스와 교차
  ///
  /// 이름 표기가 서버와 달라 매칭이 안 된 성분은 그냥 빠진다 —
  /// 보고서가 "판단 정보 부족"으로 표시할 뿐, 틀린 점수를 만들지 않는다.
  Future<Map<int, List<String>>> bstiIdsByProducts(
    List<int> productIds,
  ) async {
    if (!Env.hasApi || productIds.isEmpty) return const {};

    final index = await _buildBstiIndex();
    if (index.isEmpty) return const {};

    final out = <int, List<String>>{};
    for (final pid in productIds) {
      List<int> serverIds;
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          '/api/v1/products/$pid/ingredients',
        );
        serverIds =
            ((res.data?['ingredient_ids'] as List?) ?? const []).cast<int>();
      } on DioException {
        // 404(없는 제품)·422(분석 불가) 등 — 이 제품만 건너뛴다.
        continue;
      }
      out[pid] = [
        for (final id in serverIds)
          if (index[id] != null) index[id]!,
      ];
    }
    return out;
  }

  /// BSTI 사전 34개를 서버에서 찾아 `서버 성분 id → BSTI id` 인덱스를 만든다.
  ///
  /// 성분당 검색 1회(한글명), 실패·불일치 시 INCI 로 1회 더 — 최대 68회지만
  /// 앱 실행당 한 번이고 서버 검색은 가벼운 ILIKE 쿼리다.
  Future<Map<int, String>> _buildBstiIndex() async {
    final cached = _bstiIndex;
    if (cached != null) return cached;

    final index = <int, String>{};
    await Future.wait([
      for (final bsti in kBstiIngredients.values)
        _indexOne(bsti, index),
    ]);
    return _bstiIndex = index;
  }

  Future<void> _indexOne(BstiIngredient bsti, Map<int, String> index) async {
    // 한글명 먼저, 안 잡히면 INCI. 후보 중 **정확 일치**만 채택한다.
    for (final query in [bsti.nameKo, if (bsti.inci != null) bsti.inci!]) {
      List<Ingredient> candidates;
      try {
        candidates = await search(query);
      } on Object {
        continue; // 검색 하나 실패해도 나머지 인덱스는 만든다.
      }
      for (final c in candidates) {
        final matched = bstiIdForNames(nameKr: c.nameKor, nameEn: c.nameEng);
        if (matched == bsti.id) {
          index[c.id] = bsti.id;
          return;
        }
      }
    }
  }
}
