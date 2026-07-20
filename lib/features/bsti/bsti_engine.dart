/// BSTI 채점·진단 엔진 (프론트 전용, 백엔드 호출 없음).
///
/// Supabase의 `bsti_compute_code` / `bsti_diagnose` 함수를 Dart로 옮긴 것.
/// 답변(문항 id → 선택 보기 score) 하나만 주면 코드·유형·성분·자차까지 만들어 준다.
library;

import 'bsti_result.dart' as legacy;
import 'bsti_dataset.dart';
import 'bsti_models.dart';
import 'bsti_skin_types.dart';

/// 한 축의 채점 결과. (결과 화면의 비율 바 등에 쓰기 좋게 계산까지 포함)
class BstiAxisScore {
  const BstiAxisScore({
    required this.axis,
    required this.score,
    required this.pole,
  });

  final BstiAxis axis;

  /// 이 축 문항들의 선택 score 합.
  final double score;

  /// 판정된 극. high_pole 또는 low_pole ('O'/'D' 등).
  final String pole;

  bool get isHigh => pole == axis.highPole;

  /// 판정된 극의 라벨. 예: '지성' 또는 '건성'.
  String get poleLabel => isHigh ? axis.highLabel : axis.lowLabel;

  /// 축 최소~최대 점수 대비 높은 극(O/S/P/W) 쪽 비율(0~100).
  ///
  /// 최소 = 문항수 × 1, 최대 = 문항수 × 4. 결과 화면 게이지용.
  int get highPercent {
    final min = axis.questionCount * 1.0;
    final max = axis.questionCount * 4.0;
    if (max == min) return 50;
    final ratio = ((score - min) / (max - min)) * 100;
    return ratio.clamp(0, 100).round();
  }
}

/// 최종 진단 결과. 코드 + 유형 + (채점 근거) 축별 점수.
class BstiDiagnosis {
  const BstiDiagnosis({
    required this.code,
    required this.type,
    required this.axisScores,
  });

  /// 4글자 코드. 예: 'OSPW'.
  final String code;

  /// 매칭된 피부유형 (권장/기피 성분 child 포함).
  final BstiSkinType type;

  /// oil→sensitivity→pigment→aging 순 축별 채점.
  final List<BstiAxisScore> axisScores;

  /// 권장 성분을 실제 [BstiIngredient]로 해석해 sort_order 순으로 반환.
  List<BstiIngredient> get recommendedIngredients =>
      _resolve(type.recommend);

  /// 기피 성분을 실제 [BstiIngredient]로 해석해 sort_order 순으로 반환.
  List<BstiIngredient> get avoidIngredients => _resolve(type.avoid);

  /// 이 유형에 배정된 자외선차단제.
  BstiSunscreen? get sunscreen => kBstiSunscreens[type.sunscreenId];

  static List<BstiIngredient> _resolve(List<BstiTypeIngredient> links) {
    final sorted = [...links]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return [
      for (final link in sorted)
        if (kBstiIngredients[link.ingredientId] != null)
          kBstiIngredients[link.ingredientId]!,
    ];
  }

  /// 결과 화면이 쓰는 기존 [legacy.BstiResult] 형태로 변환.
  ///
  /// 결과 화면을 목업에서 실제 진단으로 바꿀 때 그대로 끼워 넣을 수 있다.
  legacy.BstiResult toLegacyResult() {
    return legacy.BstiResult(
      typeCode: code,
      typeName: type.personaName,
      axes: [
        for (final s in axisScores)
          legacy.BstiAxis(
            leftCode: s.axis.highPole,
            leftLabel: s.axis.highLabel,
            leftPercent: s.highPercent,
            rightCode: s.axis.lowPole,
            rightLabel: s.axis.lowLabel,
          ),
      ],
      recommendedIngredients:
          recommendedIngredients.map((e) => e.nameKo).toList(),
      cautionIngredients: avoidIngredients.map((e) => e.nameKo).toList(),
    );
  }
}

/// BSTI 채점기.
///
/// [answers]: 문항 id → 선택한 보기의 score(1~4). 예: `{1: 4, 2: 3, ..., 20: 2}`.
class BstiEngine {
  const BstiEngine._();

  /// 답변 → 4글자 코드. (SQL `bsti_compute_code`와 동일 규칙)
  ///
  /// 축별로 해당 문항들의 score를 합산해 cutoff 이상이면 high_pole, 아니면 low_pole.
  static String computeCode(Map<int, int> answers) {
    final buffer = StringBuffer();
    for (final axis in kBstiAxes) {
      final sum = _axisSum(axis.code, answers);
      buffer.write(sum >= axis.cutoff ? axis.highPole : axis.lowPole);
    }
    return buffer.toString();
  }

  /// 답변 → 코드 + 유형 + 축별 채점을 담은 진단 결과. (SQL `bsti_diagnose` 대응)
  static BstiDiagnosis diagnose(Map<int, int> answers) {
    final axisScores = <BstiAxisScore>[];
    final buffer = StringBuffer();
    for (final axis in kBstiAxes) {
      final sum = _axisSum(axis.code, answers);
      final pole = sum >= axis.cutoff ? axis.highPole : axis.lowPole;
      buffer.write(pole);
      axisScores.add(BstiAxisScore(axis: axis, score: sum, pole: pole));
    }
    final code = buffer.toString();
    final type = kBstiSkinTypes[code];
    if (type == null) {
      throw StateError('알 수 없는 BSTI 코드: $code (16개 유형에 없음)');
    }
    return BstiDiagnosis(code: code, type: type, axisScores: axisScores);
  }

  /// 한 축의 문항 score 합.
  static double _axisSum(String axisCode, Map<int, int> answers) {
    var sum = 0.0;
    for (final q in kBstiQuestions) {
      if (q.axisCode == axisCode) {
        sum += (answers[q.id] ?? 0).toDouble();
      }
    }
    return sum;
  }

  /// 성분 집합에 가장 잘 맞는 BSTI 유형을 실제 데이터로 찾는다.
  ///
  /// [bstiIngredientIds]: BSTI 성분 사전(kBstiIngredients)의 문자열 id들
  /// (예: 제품이 가진 성분들의 bstiIngredientId).
  /// 각 유형의 권장 성분(recommend)과 겹치는 개수가 가장 많은 유형을 반환한다.
  /// 동점이면 kBstiSkinTypes 순서상 먼저 오는 유형. 매칭이 전혀 없으면 null.
  static BstiSkinType? matchTypeByIngredients(
      Iterable<String> bstiIngredientIds) {
    final ids = bstiIngredientIds.toSet();
    if (ids.isEmpty) return null;

    BstiSkinType? best;
    var bestScore = 0;
    for (final type in kBstiSkinTypes.values) {
      final recommendIds = type.recommend.map((e) => e.ingredientId).toSet();
      final score = ids.intersection(recommendIds).length;
      if (score > bestScore) {
        bestScore = score;
        best = type;
      }
    }
    return bestScore > 0 ? best : null;
  }
}
