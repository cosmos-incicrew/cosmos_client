/// 제품 궁합 엔진 — 대표제품 vs 나머지 제품의 매칭 점수·성분 분류.
///
/// 비교 API(POST /products/compare) 응답과 BSTI 성분 매핑(프론트 완결)만으로
/// 계산한다 — 서버 추가 요청 없음. 점수 규칙:
///
///   기본 70점
///   + 보완성분(같이 쓰면 좋은 조합) 1쌍당 +6
///   + 공통성분이 있으면 +5 (결이 비슷한 제품)
///   - 과다성분(규제 성분이 두 제품에 겹침) 1개당 -15
///   → 5~100 사이로 자름
///
/// 근거 없는 항목은 빈 목록으로 두고 화면이 "없어요"를 보여준다 —
/// 점수를 지어내지 않는 보고서 엔진과 같은 원칙.
library;

import '../../product/data/models/product_compare.dart';

/// 같이 쓰면 좋은 성분 조합 사전 (BSTI 성분 id 기준).
///
/// 한쪽 제품에 [a], 다른 쪽에 [b]가 있으면 보완 관계로 친다. 순서 무관.
class ComplementaryPair {
  const ComplementaryPair(this.a, this.b, this.reason);

  final String a;
  final String b;

  /// 왜 좋은 조합인지 — 화면에 그대로 보여준다.
  final String reason;
}

const kComplementaryPairs = <ComplementaryPair>[
  ComplementaryPair('vcd', 'toco', '비타민C와 비타민E — 함께 쓰면 항산화 효과가 서로를 보강해요'),
  ComplementaryPair('retal', 'ha', '레티놀류와 히알루론산 — 보습이 레티놀의 건조·자극을 완화해요'),
  ComplementaryPair('retal', 'cera', '레티놀류와 세라마이드 — 장벽을 지키며 안티에이징 케어를 도와요'),
  ComplementaryPair('niac', 'ha', '나이아신아마이드와 히알루론산 — 수분과 장벽·톤 관리를 함께해요'),
  ComplementaryPair('niac', 'sal', '나이아신아마이드와 살리실산 — 피지·모공 관리 조합이에요'),
  ComplementaryPair('niac', 'retal', '나이아신아마이드와 레티놀류 — 자극을 줄이며 주름·톤을 함께 관리해요'),
  ComplementaryPair('cera', 'ha', '세라마이드와 히알루론산 — 수분을 채우고 장벽으로 잠가요'),
  ComplementaryPair('cica', 'panth', '시카와 판테놀 — 진정과 회복을 같이 돕는 조합이에요'),
  ComplementaryPair('aze', 'niac', '아젤라익애씨드와 나이아신아마이드 — 트러블·톤 관리를 함께해요'),
];

/// 발견된 보완 조합 하나.
class ComplementaryHit {
  const ComplementaryHit({required this.pair, required this.aInRep});

  final ComplementaryPair pair;

  /// true 면 [pair.a] 가 대표제품 쪽에 있다 (표시용 방향 정보).
  final bool aInRep;
}

/// 대표제품 vs 상대제품 한 쌍의 궁합 결과.
class PairMatch {
  const PairMatch({
    required this.product,
    required this.score,
    required this.verdict,
    required this.shared,
    required this.excess,
    required this.complementary,
  });

  final ComparedProduct product;

  /// 궁합 점수 (5~100).
  final int score;
  final String verdict;

  /// 공통 성분 — 두 제품 모두에 든 성분.
  final List<IngredientPresence> shared;

  /// 과다 성분 — 공통이면서 규제(한도 등)가 걸린 성분. 겹쳐 쓰면 과할 수 있다.
  final List<IngredientPresence> excess;

  /// 보완 성분 조합 — 서로 같이 쓰면 좋은 성분이 나뉘어 들어있는 경우.
  final List<ComplementaryHit> complementary;
}

abstract final class CompareMatchEngine {
  /// [repId] 대표제품 기준으로 나머지 제품 각각의 궁합을 계산한다.
  ///
  /// [bstiOf] 는 제품 id → BSTI 성분 id 목록 (없으면 보완성분만 빈 결과).
  static List<PairMatch> build(
    ProductCompareResult result,
    int repId,
    Map<int, List<String>> bstiOf,
  ) {
    final others = [
      for (final p in result.products)
        if (p.id != repId) p,
    ];
    return [for (final p in others) _pair(result, repId, p, bstiOf)];
  }

  static PairMatch _pair(
    ProductCompareResult result,
    int repId,
    ComparedProduct other,
    Map<int, List<String>> bstiOf,
  ) {
    final shared = [
      for (final ing in result.ingredientPresence)
        if (ing.productIds.contains(repId) &&
            ing.productIds.contains(other.id))
          ing,
    ];
    final excess = [
      for (final ing in shared)
        if (ing.restrictions.isNotEmpty) ing,
    ];

    // 보완 조합 — 한쪽에 a, 다른 쪽에 b (같은 제품 안의 조합은 세지 않는다:
    // "같이 쓰면"의 주체는 두 제품이다).
    final repBsti = (bstiOf[repId] ?? const []).toSet();
    final otherBsti = (bstiOf[other.id] ?? const []).toSet();
    final complementary = <ComplementaryHit>[
      for (final pair in kComplementaryPairs)
        if (repBsti.contains(pair.a) && otherBsti.contains(pair.b))
          ComplementaryHit(pair: pair, aInRep: true)
        else if (repBsti.contains(pair.b) && otherBsti.contains(pair.a))
          ComplementaryHit(pair: pair, aInRep: false),
    ];

    final score = (70 +
            complementary.length * 6 +
            (shared.isNotEmpty ? 5 : 0) -
            excess.length * 15)
        .clamp(5, 100);

    return PairMatch(
      product: other,
      score: score,
      verdict: score >= 80
          ? '잘 어울리는 조합이에요'
          : score >= 50
              ? '무난하게 같이 쓸 수 있어요'
              : '같이 쓸 땐 주의가 필요해요',
      shared: shared,
      excess: excess,
      complementary: complementary,
    );
  }
}
