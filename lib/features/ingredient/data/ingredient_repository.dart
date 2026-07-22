import 'package:dio/dio.dart';

import '../../../core/config/env.dart';
import '../../bsti/bsti.dart';
import '../../bsti/bsti_name_matcher.dart';
import '../../product/data/models/product_compare.dart';
import 'models/ingredient.dart';
import 'models/ingredient_insight.dart';

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

  /// 첫 호출 콜드스타트 대응 — 타임아웃·연결 실패는 딱 1회 재시도한다.
  ///
  /// 서버·LLM 이 막 깨어난 직후의 첫 요청은 평소보다 수 배 느려서
  /// "맨 처음 여는 제품/성분만 실패"하는 증상이 난다. 재시도 한 번이면
  /// 워밍업이 끝나 있어 대부분 성공한다. (4xx 등 진짜 오류는 즉시 던진다)
  Future<T> _retryOnce<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      final transient = e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError;
      if (!transient) rethrow;
      return run();
    }
  }

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

  /// ① 개별 성분 해설 — 성분 토글(자세히보기)에서 클릭 시 호출.
  ///
  /// GET /api/v1/ingredients/{id}/detail
  /// status "확인 불가"는 **에러가 아니다** (name 은 채워져 옴) —
  /// 정상 화면에 "아직 정보가 없습니다"를 띄운다. 404 만 잘못된 id.
  /// 502 GENERATION_FAILED / 503 EVIDENCE_UNAVAILABLE → "잠시 후 다시 시도".
  Future<IngredientDetail> getDetail(int ingredientId) async {
    if (!Env.hasApi) {
      throw StateError('API_BASE_URL 미설정 — 성분 해설은 서버가 필요합니다');
    }
    final res = await _retryOnce(() => _dio.get<Map<String, dynamic>>(
          '/api/v1/ingredients/$ingredientId/detail',
          // LLM 생성이라 오래 걸릴 수 있다 (Pro 모델 기준 ~30초 실측).
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        ));
    return IngredientDetail.fromJson(res.data ?? const {});
  }

  /// ② 단일 제품 요약 — 제품 상세 상단 (대표성분 Top-3 + 해설).
  ///
  /// POST /api/v1/ingredients/product-summary
  /// [ingredientIds] 는 검색엔진이 준 **배합순 그대로** 넘긴다 —
  /// 앞쪽 성분이 대표성분이 된다. 요청 성분이 하나도 없을 때만 404.
  /// summary 의 "주의:" 줄은 [splitCaution] 으로 분리해 강조한다.
  Future<ProductSummary> getProductSummary(List<int> ingredientIds) async {
    if (!Env.hasApi) {
      throw StateError('API_BASE_URL 미설정 — 제품 요약은 서버가 필요합니다');
    }
    final res = await _retryOnce(() => _dio.post<Map<String, dynamic>>(
          '/api/v1/ingredients/product-summary',
          data: {'ingredient_ids': ingredientIds},
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        ));
    return ProductSummary.fromJson(res.data ?? const {});
  }

  /// ③ 다중 제품 비교 해설 — 비교 화면 하단.
  ///
  /// POST /api/v1/ingredients/comparison-summary
  /// 요청 본문은 compare(검색엔진) 응답을 **그대로** 넣는다 (명세 지시 —
  /// [ProductCompareResult.toJson] 이 그 형태다).
  ///
  /// 해설은 성분 **구성의 차이**만 말한다 — 제품 간 우열·추천은 오지 않는다.
  Future<ComparisonSummary> getComparisonSummary(
    ProductCompareResult compareResult,
  ) async {
    if (!Env.hasApi) {
      throw StateError('API_BASE_URL 미설정 — 비교 해설은 서버가 필요합니다');
    }
    final res = await _retryOnce(() => _dio.post<Map<String, dynamic>>(
          '/api/v1/ingredients/comparison-summary',
          data: compareResult.toJson(),
          options: Options(receiveTimeout: const Duration(seconds: 45)),
        ));
    return ComparisonSummary.fromJson(res.data ?? const {});
  }

  /// id 목록으로 성분 조회 — 제품 상세의 성분 목록. **입력 순서 유지.**
  ///
  /// POST /api/v1/ingredients/names  {"ingredient_ids": [101, 102]}
  /// 응답: {"ingredients": [{"ingredient_id", "name_kr", "name_en"}]}
  /// 서버가 요청 순서를 유지하고, 없는 id는 이름 null 로 온다 — 그런 항목은
  /// 거른다 (이름 없는 성분은 화면에 쓸 수 없다).
  Future<List<Ingredient>> getByIds(List<int> ids) async {
    if (!Env.hasApi || ids.isEmpty) return const [];

    final res = await _retryOnce(() => _dio.post<Map<String, dynamic>>(
          '/api/v1/ingredients/names',
          data: {'ingredient_ids': ids},
          // 기본(15초)으론 첫 진입 혼잡 때 잘린다 — LLM 은 아니라 30초면 충분.
          options: Options(receiveTimeout: const Duration(seconds: 30)),
        ));
    final rows = (res.data?['ingredients'] as List?) ?? const [];
    return [
      for (final raw in rows.cast<Map<String, dynamic>>())
        if (raw['name_kr'] != null)
          Ingredient(
            id: raw['ingredient_id'] as int,
            nameKor: raw['name_kr'] as String?,
            nameEng: (raw['name_en'] ?? raw['name_kr'] ?? '') as String,
          ),
    ];
  }

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
