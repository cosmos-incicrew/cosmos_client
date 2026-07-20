/// 성분 모델. 서버 RAG 데이터 설계(ingredients + restrictions + synonyms 조인)를 반영한다.
///
/// 중요 규칙 (서버 데이터 설계 문서 기준):
///   - 결측 필드는 빈 문자열이 아니라 반드시 null. 화면에서 null이면 해당 항목을 생략한다.
///   - restrictions.safetyNote 가 null → "안전성 확인 불가"로 표시. 절대 "안전함"으로 단정하지 않는다.
///   - sourceRef 가 null → 출처 미표기.
class Ingredient {
  const Ingredient({
    required this.id,
    required this.nameKor,
    required this.nameEng,
    this.efficacy,
    this.productProperty,
    this.recommendedSkinType,
    this.originDefinition,
    this.sourceRef,
    this.restriction,
    this.synonyms = const [],
    this.bstiIngredientId,
  });

  final int id; // ingredient_id — 모든 조인의 기준 키
  final String? nameKor; // 결측 시 null
  final String nameEng; // INCI 표기 (식별자)
  final String? efficacy;
  final String? productProperty;
  final String? recommendedSkinType;
  final String? originDefinition;

  /// 출처 원문 문자열 그대로. 파싱하지 않는다. null이면 출처 미표기.
  final String? sourceRef;

  /// 제한/주의사항. null이면 규제 정보 없음.
  final IngredientRestriction? restriction;

  final List<String> synonyms;

  /// BSTI 성분 사전(kBstiIngredients)의 문자열 id (예: 'niac'). 없으면 null.
  /// 이 값으로 "어느 BSTI 유형이 이 성분을 권장하는지" 실제 매칭한다.
  final String? bstiIngredientId;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['ingredient_id'] as int,
      nameKor: json['name_kor'] as String?,
      nameEng: json['name_eng'] as String,
      efficacy: json['efficacy'] as String?,
      productProperty: json['product_property'] as String?,
      recommendedSkinType: json['recommended_skin_type'] as String?,
      originDefinition: json['origin_definition'] as String?,
      sourceRef: json['source_ref'] as String?,
      restriction: json['restrictions'] == null
          ? null
          : IngredientRestriction.fromJson(
              json['restrictions'] as Map<String, dynamic>),
      synonyms: (json['synonyms'] as List?)?.cast<String>() ?? const [],
      bstiIngredientId: json['bsti_ingredient_id'] as String?,
    );
  }

  /// 화면 표시용 대표 이름 (한글 우선, 없으면 영문).
  String get displayName => nameKor ?? nameEng;
}

// 목(mock) 성분 데이터는 lib/core/mock/mock_data.dart 로 분리했다.
// (백엔드 연동 시 그 폴더째 삭제)

/// 성분 제한/주의사항. safetyNote가 null이면 "안전성 확인 불가".
class IngredientRestriction {
  const IngredientRestriction({
    this.safetyNote,
    this.limitCond,
    this.blendRegulation,
    this.provisAtrcl,
    this.isRegisteredKorea,
  });

  final String? safetyNote; // null → "확인 불가"
  final String? limitCond; // 제한사항
  final String? blendRegulation; // 배합규제
  final String? provisAtrcl; // 단서조항
  final bool? isRegisteredKorea; // 국내 등록 여부 (경고 분기)

  factory IngredientRestriction.fromJson(Map<String, dynamic> json) {
    return IngredientRestriction(
      safetyNote: json['safety_note'] as String?,
      limitCond: json['limit_cond'] as String?,
      blendRegulation: json['blend_regulation'] as String?,
      provisAtrcl: json['provis_atrcl'] as String?,
      isRegisteredKorea: json['is_registered_korea'] as bool?,
    );
  }

  /// 안전성 표시 문구. null이면 단정하지 않고 "확인 불가".
  String get safetyDisplay => safetyNote ?? '안전성 확인 불가';
}
