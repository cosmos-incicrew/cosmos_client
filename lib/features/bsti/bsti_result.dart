/// BSTI(피부 MBTI) 검사 결과 모델.
///
/// 16타입은 4개 축의 조합으로 결정된다 (피그마 온보딩 OSPT/OSPW 설명 기준):
///   - O(지성) ↔ D(건성)
///   - S(민감) ↔ R(저항)
///   - P(색소) ↔ N(비색소)
///   - W(주름) ↔ T(탱탱)
/// 결과 화면은 각 축의 비율(%)과 타입 코드(예: OSPW), 타입 별명, 권장/주의 성분을 보여준다.
///
/// TODO: 실제 필드는 서버 BSTI 응답 명세(API 명세서) 확정 후 맞춘다. 지금은 목업 기준.
class BstiResult {
  const BstiResult({
    required this.typeCode,
    required this.typeName,
    required this.axes,
    this.recommendedIngredients = const [],
    this.cautionIngredients = const [],
  });

  /// 4글자 타입 코드. 예: "OSPW"
  final String typeCode;

  /// 타입 별명. 예: "진정이 먼저인 풀코스 케어 수련생"
  final String typeName;

  /// 4개 축의 세부 비율.
  final List<BstiAxis> axes;

  /// 권장 성분명 리스트. 예: ["나이아신아마이드", "글리세롤", "히알루론산"]
  final List<String> recommendedIngredients;

  /// 주의 성분명 리스트.
  final List<String> cautionIngredients;

  factory BstiResult.fromJson(Map<String, dynamic> json) {
    return BstiResult(
      typeCode: json['type_code'] as String,
      typeName: (json['type_name'] ?? '') as String,
      axes: (json['axes'] as List?)
              ?.map((e) => BstiAxis.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      recommendedIngredients:
          (json['recommended_ingredients'] as List?)?.cast<String>() ?? const [],
      cautionIngredients:
          (json['caution_ingredients'] as List?)?.cast<String>() ?? const [],
    );
  }
}

/// BSTI 한 축의 결과. 예: O(지성) 75% vs D(건성) 25%
class BstiAxis {
  const BstiAxis({
    required this.leftCode,
    required this.leftLabel,
    required this.leftPercent,
    required this.rightCode,
    required this.rightLabel,
  });

  final String leftCode; // "O"
  final String leftLabel; // "지성"
  final int leftPercent; // 75  (오른쪽은 100 - leftPercent)
  final String rightCode; // "D"
  final String rightLabel; // "건성"

  int get rightPercent => 100 - leftPercent;

  factory BstiAxis.fromJson(Map<String, dynamic> json) {
    return BstiAxis(
      leftCode: json['left_code'] as String,
      leftLabel: json['left_label'] as String,
      leftPercent: json['left_percent'] as int,
      rightCode: json['right_code'] as String,
      rightLabel: json['right_label'] as String,
    );
  }
}

/// BSTI 설문 문항 (25문항).
class BstiQuestion {
  const BstiQuestion({
    required this.id,
    required this.text,
    required this.options,
  });

  final int id;
  final String text;
  final List<BstiOption> options;

  factory BstiQuestion.fromJson(Map<String, dynamic> json) {
    return BstiQuestion(
      id: json['id'] as int,
      text: json['text'] as String,
      options: (json['options'] as List)
          .map((e) => BstiOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BstiOption {
  const BstiOption({required this.label, required this.value});

  final String label;

  /// 채점용 값 (어느 축에 가중되는지 등은 서버가 판단).
  final String value;

  factory BstiOption.fromJson(Map<String, dynamic> json) {
    return BstiOption(
      label: json['label'] as String,
      value: json['value'] as String,
    );
  }
}
