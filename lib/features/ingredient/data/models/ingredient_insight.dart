/// 성분 해설 API 응답 모델 (①개별 해설 / ②제품 요약 / ③비교 해설).
///
/// 노션 "성분 해설 API 명세" 를 그대로 옮겼다.
///
/// 공통 규칙:
/// - `status` 는 "ok" 또는 "확인 불가". **확인 불가는 에러가 아니다** —
///   성분은 실재하지만 해설할 정보가 아직 없다는 뜻. 정상 화면에 안내를 띄운다.
/// - `source_verified == false` 는 검증 안 된 출처를 서버가 제거했다는 뜻.
///   **본문은 유효하다.** 출처만 표시하지 않는다.
library;

/// 해설 상태.
enum InsightStatus {
  ok('ok'),

  /// 정보 부족 — 에러가 아니라 "아직 정보가 없습니다" 안내 대상.
  unavailable('확인 불가');

  const InsightStatus(this.code);
  final String code;

  static InsightStatus fromCode(String? code) =>
      code == 'ok' ? InsightStatus.ok : InsightStatus.unavailable;
}

/// safety 문구의 세 형태 (명세 §2).
enum SafetyKind {
  /// "[공식 규제] ..." 로 시작 — 경고색으로 강조.
  official,

  /// 일반 안전성 참고 — 보통 표시.
  general,

  /// "안전성 확인 불가" — **"안전하다"가 아니라 "모른다"**.
  /// 절대 안전하다고 표시하면 안 된다.
  unknown,
}

/// safety 문자열 → 표시 분류.
SafetyKind classifySafety(String? safety) {
  if (safety == null || safety.trim().isEmpty || safety.contains('안전성 확인 불가')) {
    return SafetyKind.unknown;
  }
  if (safety.startsWith('[공식 규제]')) return SafetyKind.official;
  return SafetyKind.general;
}

/// ②③의 summary 에서 "주의: " 줄을 분리한다 (명세 §7 — 강조 표시용).
///
/// 주의 줄이 없으면 caution 은 null.
({String body, String? caution}) splitCaution(String summary) {
  final lines = summary.split('\n');
  final cautions = <String>[];
  final body = <String>[];
  for (final line in lines) {
    (line.trimLeft().startsWith('주의:') ? cautions : body).add(line);
  }
  return (
    body: body.join('\n').trim(),
    caution: cautions.isEmpty ? null : cautions.join('\n').trim(),
  );
}

/// ① 개별 성분 해설 — GET /api/v1/ingredients/{id}/detail
class IngredientDetail {
  const IngredientDetail({
    required this.status,
    required this.ingredientId,
    this.name,
    this.body,
    this.safety,
    this.referenceSource,
    this.sourceVerified = true,
    this.reason,
  });

  final InsightStatus status;
  final int ingredientId;
  final String? name;
  final String? body;
  final String? safety;
  final String? referenceSource;

  /// false = 검증 안 된 출처를 제거함. 본문은 정상 — 출처만 숨긴다.
  final bool sourceVerified;

  /// "확인 불가"일 때만 사유.
  final String? reason;

  SafetyKind get safetyKind => classifySafety(safety);

  factory IngredientDetail.fromJson(Map<String, dynamic> json) {
    return IngredientDetail(
      status: InsightStatus.fromCode(json['status'] as String?),
      ingredientId: json['ingredient_id'] as int,
      name: json['name'] as String?,
      body: json['body'] as String?,
      safety: json['safety'] as String?,
      referenceSource: json['reference_source'] as String?,
      sourceVerified: json['source_verified'] as bool? ?? true,
      reason: json['reason'] as String?,
    );
  }
}

/// 대표 성분 (배합순 상위, 최대 3개).
class TopIngredient {
  const TopIngredient({required this.ingredientId, this.name});

  final int ingredientId;
  final String? name;

  factory TopIngredient.fromJson(Map<String, dynamic> json) {
    return TopIngredient(
      ingredientId: json['ingredient_id'] as int,
      name: json['name'] as String?,
    );
  }
}

/// ② 단일 제품 요약 — POST /api/v1/ingredients/product-summary
class ProductSummary {
  const ProductSummary({
    required this.status,
    this.topIngredients = const [],
    this.summary,
    this.sourceVerified = true,
    this.reason,
  });

  final InsightStatus status;
  final List<TopIngredient> topIngredients;

  /// 권장 피부타입 + 특징 + (있으면) "주의: " 줄. [splitCaution] 으로 분리.
  final String? summary;
  final bool sourceVerified;
  final String? reason;

  factory ProductSummary.fromJson(Map<String, dynamic> json) {
    return ProductSummary(
      status: InsightStatus.fromCode(json['status'] as String?),
      topIngredients: [
        for (final t in (json['top_ingredients'] as List?) ?? const [])
          TopIngredient.fromJson(t as Map<String, dynamic>),
      ],
      summary: json['summary'] as String?,
      sourceVerified: json['source_verified'] as bool? ?? true,
      reason: json['reason'] as String?,
    );
  }
}

/// ③ 다중 제품 비교 해설 — POST /api/v1/ingredients/comparison-summary
///
/// ⚠️ 해설은 성분 **구성의 차이**만 말한다. 제품 간 우열·추천은 하지 않는다
/// (배합 비율이 비공개라 판단 근거가 없음 — 명세 §4).
class ComparisonSummary {
  const ComparisonSummary({
    required this.status,
    this.summary,
    this.sourceVerified = true,
    this.reason,
  });

  final InsightStatus status;
  final String? summary;
  final bool sourceVerified;
  final String? reason;

  factory ComparisonSummary.fromJson(Map<String, dynamic> json) {
    return ComparisonSummary(
      status: InsightStatus.fromCode(json['status'] as String?),
      summary: json['summary'] as String?,
      sourceVerified: json['source_verified'] as bool? ?? true,
      reason: json['reason'] as String?,
    );
  }
}
