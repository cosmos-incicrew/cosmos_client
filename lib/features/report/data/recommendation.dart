/// 맞춤 추천 (RAG) — POST /api/v1/recommendations 응답 모델.
///
/// 요청 바디 없음 — 서버가 JWT 의 user_id 로 프로필·BSTI·화장대를 조회해
/// 내부 질의를 만든다. 근거 부족(insufficient_evidence)은 **에러가 아니라
/// HTTP 200 정형 응답**이다.
///
/// ⚠️ 서버 구버전 호환: 배포 서버가 아직 구형 응답
/// (`recommended_ingredients` + `message`/`suggested_action`)이면
/// [RecommendationResult.fromJson] 이 자동으로 새 모델로 옮겨 담는다 —
/// 서버가 새 명세로 올라오면 코드 수정 없이 서사 3섹션이 살아난다.
library;

/// 추천 상태. [profileRequired] 는 HTTP 409(PROFILE_ONBOARDING_REQUIRED)를
/// 저장소가 정형 상태로 바꾼 것 — 화면은 프로필 입력 CTA 를 띄운다.
enum RecoStatus { ok, insufficientEvidence, profileRequired }

/// 서사 3섹션 — 번호·제목 접두어 없이 본문만 온다.
class RecoAnswer {
  const RecoAnswer({this.causeAnalysis, this.recommendation, this.usageGuide});

  final String? causeAnalysis; // ① 원인 분석
  final String? recommendation; // ② 추천 성분과 근거
  final String? usageGuide; // ③ 사용법·관리법

  factory RecoAnswer.fromJson(Map<String, dynamic> json) => RecoAnswer(
        causeAnalysis: json['cause_analysis'] as String?,
        recommendation: json['recommendation'] as String?,
        usageGuide: json['usage_guide'] as String?,
      );
}

/// 근거 알림 — 약하거나 없을 때만 온다. `advisory != null` 이면 배너,
/// `action` 이 있으면 CTA 버튼.
class RecoAdvisory {
  const RecoAdvisory({required this.code, required this.message, this.action});

  /// weak_evidence | no_evidence | no_candidates
  final String code;
  final String message;

  /// retry_with_other_concerns | take_bsti | retry_later | null
  final String? action;

  factory RecoAdvisory.fromJson(Map<String, dynamic> json) => RecoAdvisory(
        code: (json['code'] ?? '') as String,
        message: (json['message'] ?? '') as String,
        action: json['action'] as String?,
      );
}

/// 유사 상담 케이스 근거 — 버튼을 누르면 팝업으로 보여준다.
class RecoCase {
  const RecoCase({
    required this.id,
    required this.targetConcern,
    this.gender,
    this.age,
    this.skinType,
    this.recommendedIngredients = const [],
    this.question,
    this.answer,
  });

  final String id;
  final String targetConcern;
  final String? gender;
  final int? age;
  final String? skinType;
  final List<String> recommendedIngredients;
  final String? question;
  final String? answer;

  /// 팝업 상단 프로필 한 줄 (예: '37세 · 여성 · 건성').
  String get profileLine => [
        if (age != null) '$age세',
        if (gender != null) gender!,
        if (skinType != null) skinType!,
      ].join(' · ');

  factory RecoCase.fromJson(Map<String, dynamic> json) => RecoCase(
        id: (json['id'] ?? '') as String,
        targetConcern: (json['target_concern'] ?? '') as String,
        gender: json['gender'] as String?,
        age: json['age'] as int?,
        skinType: json['skin_type'] as String?,
        recommendedIngredients:
            ((json['recommended_ingredients'] as List?) ?? const [])
                .cast<String>(),
        question: json['question'] as String?,
        answer: json['answer'] as String?,
      );
}

/// 성분별 규제 경고 (임신수유주의·알레르기유발·한도·안전성확인불가·고민상충).
class RecoWarning {
  const RecoWarning({required this.type, required this.text});

  final String type;
  final String text;

  factory RecoWarning.fromJson(Map<String, dynamic> json) => RecoWarning(
        type: (json['type'] ?? '') as String,
        text: (json['text'] ?? '') as String,
      );
}

/// 추천 성분 근거 하나 — 성분을 누르면 이 내용이 시트로 뜬다.
class RecoIngredient {
  const RecoIngredient({
    required this.nameKor,
    this.inci,
    this.efficacy,
    this.safetyNote,
    this.concentration,
    this.reason,
    this.warnings = const [],
    this.sourceTitles = const [],
    this.badges = const [],
    this.owned = false,
  });

  final String nameKor;
  final String? inci;
  final String? efficacy;

  /// 성분 고유의 서술형 주의.
  final String? safetyNote;

  /// 권장 농도 (예: '0.1~1.0%').
  final String? concentration;

  /// 구버전 응답의 성분별 추천 사유 — 새 명세에는 없다 (answer 로 통합).
  final String? reason;

  final List<RecoWarning> warnings;

  /// 구버전 응답의 근거 문서 제목들.
  final List<String> sourceTitles;

  /// 기능성 고시 배지 (예: '미백').
  final List<String> badges;

  /// 이미 화장대에 보유한 성분인지.
  final bool owned;

  factory RecoIngredient.fromJson(Map<String, dynamic> json) => RecoIngredient(
        nameKor: (json['name_kor'] ?? '') as String,
        inci: json['inci'] as String?,
        efficacy: json['efficacy'] as String?,
        safetyNote: json['safety_note'] as String?,
        concentration: json['concentration'] as String?,
        reason: json['reason'] as String?,
        warnings: [
          for (final w in (json['warnings'] as List?) ?? const [])
            RecoWarning.fromJson(w as Map<String, dynamic>),
        ],
        sourceTitles: [
          for (final s in (json['sources'] as List?) ?? const [])
            if ((s as Map<String, dynamic>)['title'] != null)
              s['title'] as String,
        ],
        badges: ((json['badges'] as List?) ?? const []).cast<String>(),
        owned: json['owned'] as bool? ?? false,
      );
}

/// 종합 추천 제품 — 추천 성분이 실제로 든 제품 (명세 §top_products).
class RecoProduct {
  const RecoProduct({
    required this.productId,
    required this.productName,
    this.brand,
    this.productUrl,
    this.mainCategory,
    this.matchedIngredients = const [],
  });

  final int productId;
  final String productName;
  final String? brand;
  final String? productUrl;
  final String? mainCategory;

  /// 이 제품이 추천된 이유가 된 성분 이름들.
  final List<String> matchedIngredients;

  factory RecoProduct.fromJson(Map<String, dynamic> json) => RecoProduct(
        productId: json['product_id'] as int,
        productName: (json['product_name'] ?? '') as String,
        brand: json['brand'] as String?,
        productUrl: json['product_url'] as String?,
        mainCategory: json['main_category'] as String?,
        matchedIngredients:
            ((json['matched_ingredients'] as List?) ?? const [])
                .cast<String>(),
      );
}

/// 추천에 쓰인 프로필 — 화면의 "무엇 기준 분석인지" 표기용.
class RecoProfile {
  const RecoProfile({this.age, this.gender, this.bstiType, this.concerns = const []});

  final int? age;
  final String? gender; // female | male
  final String? bstiType;

  /// 서버 고민 코드 (acne, redness, …) — 프론트 SkinConcern.name 과 같다.
  final List<String> concerns;

  factory RecoProfile.fromJson(Map<String, dynamic> json) => RecoProfile(
        age: json['age'] as int?,
        gender: json['gender'] as String?,
        bstiType: json['bsti_type'] as String?,
        concerns: ((json['concerns'] as List?) ?? const []).cast<String>(),
      );
}

/// 추천 응답 전체.
class RecommendationResult {
  const RecommendationResult({
    required this.status,
    this.answer,
    this.cases = const [],
    this.ingredients = const [],
    this.products = const [],
    this.advisory,
    this.profile,
    this.disclaimer,
  });

  final RecoStatus status;
  final RecoAnswer? answer;
  final List<RecoCase> cases;
  final List<RecoIngredient> ingredients;

  /// 종합 추천 제품 (top_products).
  final List<RecoProduct> products;
  final RecoAdvisory? advisory;
  final RecoProfile? profile;
  final String? disclaimer;

  /// 409 PROFILE_ONBOARDING_REQUIRED → 정형 상태.
  factory RecommendationResult.profileRequired(String message) =>
      RecommendationResult(
        status: RecoStatus.profileRequired,
        advisory: RecoAdvisory(code: 'profile_required', message: message),
      );

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    // ── 구버전 호환 ──
    // 새 명세는 `answer`/`ingredients` 키, 구버전은 `recommended_ingredients`.
    if (json.containsKey('recommended_ingredients')) {
      final advisoryMsg = json['message'] as String?;
      return RecommendationResult(
        status: json['status'] == 'ok'
            ? RecoStatus.ok
            : RecoStatus.insufficientEvidence,
        ingredients: [
          for (final raw in (json['recommended_ingredients'] as List?) ?? const [])
            RecoIngredient.fromJson(raw as Map<String, dynamic>),
        ],
        advisory: advisoryMsg == null
            ? null
            : RecoAdvisory(
                code: 'weak_evidence',
                message: advisoryMsg,
                action: json['suggested_action'] as String?,
              ),
        profile: json['context_used'] == null
            ? null
            : RecoProfile.fromJson(json['context_used'] as Map<String, dynamic>),
        disclaimer: json['disclaimer'] as String?,
      );
    }

    return RecommendationResult(
      status: json['status'] == 'ok'
          ? RecoStatus.ok
          : RecoStatus.insufficientEvidence,
      answer: json['answer'] == null
          ? null
          : RecoAnswer.fromJson(json['answer'] as Map<String, dynamic>),
      cases: [
        for (final raw in (json['cases'] as List?) ?? const [])
          RecoCase.fromJson(raw as Map<String, dynamic>),
      ],
      // 최종 명세는 top_ingredients — 이전 키(ingredients)도 함께 받는다.
      ingredients: [
        for (final raw in (json['top_ingredients'] ??
                json['ingredients'] ??
                const []) as List)
          RecoIngredient.fromJson(raw as Map<String, dynamic>),
      ],
      products: [
        for (final raw in (json['top_products'] as List?) ?? const [])
          RecoProduct.fromJson(raw as Map<String, dynamic>),
      ],
      advisory: json['advisory'] == null
          ? null
          : RecoAdvisory.fromJson(json['advisory'] as Map<String, dynamic>),
      profile: json['user_profile'] == null
          ? null
          : RecoProfile.fromJson(json['user_profile'] as Map<String, dynamic>),
      disclaimer: json['disclaimer'] as String?,
    );
  }
}
