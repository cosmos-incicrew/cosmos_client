/// 다중 제품 비교 API 응답 모델.
///
/// `POST /api/v1/products/compare` 의 계약(노션 "API JSON" 문서 = 서버
/// `app/modules/product_compare/schemas.py`)을 그대로 옮겼다.
/// 필드명이 다르면 조용히 null 로 파싱되므로 서버 표기(snake_case)를 지킨다.
library;

/// 성분이 비교 제품들 중 어디에 포함되는지.
enum PresenceType {
  /// 비교한 모든 제품에 포함.
  all('all'),

  /// 2개 이상이지만 전부는 아닌 일부 제품에 포함. (2개 비교 시엔 안 나옴)
  partial('partial'),

  /// 한 제품에만 포함.
  single('single');

  const PresenceType(this.code);
  final String code;

  static PresenceType fromCode(String code) {
    return PresenceType.values.firstWhere(
      (e) => e.code == code,
      // 서버에 새 값이 생겨도 파싱이 터지지 않게 — 목록엔 뜨되 구분만 보수적으로.
      orElse: () => PresenceType.single,
    );
  }
}

/// 성분 하나의 구조화된 주의사항 규칙.
///
/// DB의 구조화 규칙 그대로이며, 사용자용 설명 문장이 아니다.
class CompareRestriction {
  const CompareRestriction({
    this.restrictionId,
    this.regulateType,
    this.provisAtrcl,
    this.limitCond,
    this.isRegisteredKorea,
  });

  final int? restrictionId;
  final String? regulateType; // 규제 유형 (예: '한도')
  final String? provisAtrcl; // 단서·적용 조건
  final String? limitCond; // 사용 한도 조건
  final bool? isRegisteredKorea; // 국내 등록 여부

  factory CompareRestriction.fromJson(Map<String, dynamic> json) {
    return CompareRestriction(
      restrictionId: json['restriction_id'] as int?,
      regulateType: json['regulate_type'] as String?,
      provisAtrcl: json['provis_atrcl'] as String?,
      limitCond: json['limit_cond'] as String?,
      isRegisteredKorea: json['is_registered_korea'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
        'restriction_id': restrictionId,
        'regulate_type': regulateType,
        'provis_atrcl': provisAtrcl,
        'limit_cond': limitCond,
        'is_registered_korea': isRegisteredKorea,
      };
}

/// 성분 하나가 어느 제품들에 들었는지 + 주의사항.
class IngredientPresence {
  const IngredientPresence({
    required this.ingredientId,
    required this.nameKr,
    required this.productIds,
    required this.presenceType,
    this.restrictions = const [],
  });

  final int ingredientId;
  final String nameKr;

  /// 이 성분을 포함한 제품 id 목록.
  final List<int> productIds;
  final PresenceType presenceType;
  final List<CompareRestriction> restrictions;

  factory IngredientPresence.fromJson(Map<String, dynamic> json) {
    return IngredientPresence(
      ingredientId: json['ingredient_id'] as int,
      nameKr: json['name_kr'] as String,
      productIds: ((json['product_ids'] as List?) ?? const []).cast<int>(),
      presenceType: PresenceType.fromCode(json['presence_type'] as String),
      restrictions: [
        for (final r in (json['restrictions'] as List?) ?? const [])
          CompareRestriction.fromJson(r as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient_id': ingredientId,
        'name_kr': nameKr,
        'product_ids': productIds,
        'presence_type': presenceType.code,
        'restrictions': [for (final r in restrictions) r.toJson()],
      };
}

/// 비교가 완료된 제품 (id + 이름만).
class ComparedProduct {
  const ComparedProduct({required this.id, required this.productName});

  final int id;
  final String productName;

  factory ComparedProduct.fromJson(Map<String, dynamic> json) {
    return ComparedProduct(
      id: json['id'] as int,
      productName: json['product_name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'product_name': productName};
}

/// 다중 제품 비교 결과.
class ProductCompareResult {
  const ProductCompareResult({
    required this.products,
    required this.ingredientPresence,
    required this.ingredientIds,
  });

  final List<ComparedProduct> products;
  final List<IngredientPresence> ingredientPresence;

  /// 비교 제품 전체 성분 id (중복 제거됨).
  /// 후속 성분 정보 요청(product-summary 등)에 **이 목록을 그대로** 쓴다 —
  /// ingredient_presence 에서 다시 모을 필요 없다 (명세서 지시).
  final List<int> ingredientIds;

  factory ProductCompareResult.fromJson(Map<String, dynamic> json) {
    return ProductCompareResult(
      products: [
        for (final p in (json['products'] as List?) ?? const [])
          ComparedProduct.fromJson(p as Map<String, dynamic>),
      ],
      ingredientPresence: [
        for (final i in (json['ingredient_presence'] as List?) ?? const [])
          IngredientPresence.fromJson(i as Map<String, dynamic>),
      ],
      ingredientIds:
          ((json['ingredient_ids'] as List?) ?? const []).cast<int>(),
    );
  }

  /// 비교 해설(③ comparison-summary) 요청 본문 — 명세: "compare 응답을 그대로".
  Map<String, dynamic> toJson() => {
        'products': [for (final p in products) p.toJson()],
        'ingredient_presence': [
          for (final i in ingredientPresence) i.toJson(),
        ],
        'ingredient_ids': ingredientIds,
      };
}
