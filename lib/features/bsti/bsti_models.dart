/// BSTI 데이터 도메인 모델.
///
/// Supabase 스키마(`bsti_*` 테이블)를 DB 없이 코드로 그대로 옮긴 것.
/// - [BstiIngredient]      : 성분 사전 한 항목 (bsti_ingredients)
/// - [BstiSunscreen]       : 자외선차단제 유형 (bsti_sunscreens)
/// - [BstiAxis]            : 평가 축 + 채점 컷오프 (bsti_axes)
/// - [BstiQuestion]/[BstiOption] : 진단 문항·보기 (bsti_questions/options)
/// - [BstiTypeIngredient]  : 유형↔성분 매핑 한 줄 (bsti_type_ingredients)
/// - [BstiSkinType]        : 16개 피부유형 (bsti_skin_types) — child로 권장/기피 성분을 품음
///
/// 실제 데이터는 [bsti_dataset.dart]에, 채점/조회 로직은 [bsti_engine.dart]에 있다.
library;

/// 성분 성격 분류. DB의 category 문자열을 그대로 보존.
enum BstiIngredientCategory {
  barrier, // 장벽
  humectant, // 보습(수분끌기)
  soothing, // 진정
  emollient, // 유연(유분보강)
  multi, // 멀티벤핏
  exfoliant, // 각질/피지
  sebum, // 피지
  retinoid, // 레티노이드
  antioxidant, // 항산화
  brightening, // 미백
  antiaging, // 항노화
  comedogenic, // 모공막힘(기피)
  irritant, // 자극(기피)
}

/// 성분 하나. (bsti_ingredients)
class BstiIngredient {
  const BstiIngredient({
    required this.id,
    required this.nameKo,
    this.inci,
    this.role,
    required this.category,
    this.refCodes = const [],
  });

  final String id; // 'niac'
  final String nameKo; // '나이아신아마이드'
  final String? inci; // 'Niacinamide'
  final String? role; // '피지↓·진정·미백·항산화 (멀티벤핏)'
  final BstiIngredientCategory category;
  final List<String> refCodes; // ['S3','S8'] → bsti_references 참조
}

/// 자외선차단제 유형. (bsti_sunscreens)
class BstiSunscreen {
  const BstiSunscreen({
    required this.id,
    required this.nameKo,
    this.note,
    this.refCodes = const [],
  });

  final String id; // 'tint'
  final String nameKo;
  final String? note;
  final List<String> refCodes;
}

/// 근거 논문 한 건. (bsti_references)
class BstiReference {
  const BstiReference({
    required this.code,
    required this.title,
    required this.url,
  });

  final String code; // 'S1'
  final String title;
  final String url;
}

/// 평가 축 + 채점 컷오프. (bsti_axes)
///
/// 축 점수합이 [cutoff] 이상이면 [highPole], 미만이면 [lowPole].
class BstiAxis {
  const BstiAxis({
    required this.code,
    required this.label,
    required this.highPole,
    required this.highLabel,
    required this.lowPole,
    required this.lowLabel,
    required this.questionCount,
    required this.cutoff,
  });

  final String code; // 'oil'
  final String label; // '유·수분'
  final String highPole; // 'O'
  final String highLabel; // '지성'
  final String lowPole; // 'D'
  final String lowLabel; // '건성'
  final int questionCount; // 5
  final double cutoff; // 12.5 (= 2.5 * questionCount)
}

/// 진단 문항 보기 하나. (bsti_question_options)
class BstiOption {
  const BstiOption({
    required this.label,
    required this.score,
    required this.position,
  });

  final String label; // '번들거려요'
  final int score; // 1~4 (4 = 높은 극 쪽)
  final int position; // 보기 순서
}

/// 진단 문항 하나. (bsti_questions + options)
class BstiQuestion {
  const BstiQuestion({
    required this.id,
    required this.axisCode,
    required this.position,
    required this.text,
    required this.options,
  });

  final int id;
  final String axisCode; // 'oil' — 어느 축에 가중되는지
  final int position;
  final String text;
  final List<BstiOption> options;
}

/// 유형↔성분 매핑 한 줄. (bsti_type_ingredients)
///
/// 성분 자체가 아니라 "이 유형에서 이 성분을 어떻게 다루는지"를 나타낸다.
class BstiTypeIngredient {
  const BstiTypeIngredient({
    required this.ingredientId,
    required this.isMultibenefit,
    required this.sortOrder,
  });

  final String ingredientId; // 'niac' → BstiDataset.ingredients 로 조회
  final bool isMultibenefit; // 수식어: 여러 고민을 한 번에 잡는 멀티벤핏 성분
  final int sortOrder; // 유형 내 노출 순서
}

/// 16개 피부유형 중 하나. (bsti_skin_types)
///
/// child 구조: 권장/기피 성분 리스트를 유형이 직접 품는다.
class BstiSkinType {
  const BstiSkinType({
    required this.code,
    required this.personaName,
    required this.tagline,
    required this.oil,
    required this.sensitivity,
    required this.pigment,
    required this.aging,
    required this.summary,
    required this.careOrder,
    required this.sunscreenId,
    required this.recommend,
    required this.avoid,
  });

  final String code; // 'OSPW'
  final String personaName; // '진정이 먼저인 풀코스 케어 수련생'
  final String tagline; // 한 줄 소개
  final String oil; // 'O' / 'D'
  final String sensitivity; // 'S' / 'R'
  final String pigment; // 'P' / 'N'
  final String aging; // 'W' / 'T'
  final String summary; // 유형 요약 설명
  final List<String> careOrder; // ['진정·장벽','선크림','미백','안티에이징']
  final String sunscreenId; // → BstiDataset.sunscreens 로 조회

  /// 권장 성분 (sort_order 순).
  final List<BstiTypeIngredient> recommend;

  /// 기피 성분 (sort_order 순).
  final List<BstiTypeIngredient> avoid;

  /// 유형별 고양이 캐릭터 이미지 경로. 예: 'assets/images/bsti/cat/OSPW.png'
  ///
  /// 파일명은 [code]로 자동 생성되므로, 그 이름으로 PNG를 넣기만 하면 된다.
  String get catImageAsset => 'assets/images/bsti/cat/$code.png';

  /// 유형별 영문(코드) 라벨 이미지 경로. 예: 'assets/images/bsti/label/OSPW.png'
  String get labelImageAsset => 'assets/images/bsti/label/$code.png';
}
