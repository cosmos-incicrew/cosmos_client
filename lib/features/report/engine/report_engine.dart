import '../../bsti/bsti.dart';
import '../../my_shelf/data/shelf_preference.dart';

/// 제품 하나에 대한 적합도 평가.
class ProductMatch {
  const ProductMatch({
    required this.name,
    required this.recommendHits,
    required this.avoidHits,
    required this.score,
    this.productId,
    this.recommendIds = const [],
    this.avoidIds = const [],
  });

  final String name;

  /// 제품 id — 제품 상세로 이동할 때 쓴다.
  final int? productId;

  /// 이 제품에서 실제로 매칭된 권장 성분 (BSTI id) — 토글로 펼쳐 보여준다.
  final List<String> recommendIds;

  /// 이 제품에서 실제로 매칭된 주의 성분 (BSTI id).
  final List<String> avoidIds;

  /// 내 유형의 권장성분과 겹친 개수.
  final int recommendHits;

  /// 내 유형의 주의성분과 겹친 개수.
  final int avoidHits;

  /// 적합도 0~100. 권장/주의가 하나도 없으면 판단 불가 → null.
  final int? score;

  /// 근거가 하나도 없어 점수를 못 매긴 경우.
  bool get unknown => score == null;

  String get verdict {
    final s = score;
    if (s == null) return '판단 정보 부족';
    if (s >= 80) return '잘 맞아요';
    if (s >= 50) return '무난해요';
    return '주의가 필요해요';
  }
}

/// 화장대 종합 보고서.
class ShelfReport {
  const ShelfReport({
    required this.typeCode,
    required this.matches,
    required this.totalScore,
    this.missingIngredientIds = const [],
    this.conflicts = const [],
  });

  /// 화장대 제품 **여러 개에 겹치는 규제 성분** — 함께 쓰면 과할 수 있는 조합.
  /// 서버 비교 API(POST /products/compare)의 규제 정보로 계산한다.
  final List<ConflictIngredient> conflicts;

  /// 충돌 반영 사본 — 총점에서 충돌당 7점을 감점한다 (0 미만 방지).
  /// 감점 근거는 [details] 에 그대로 드러난다 (몰래 깎지 않는다).
  ShelfReport withConflicts(List<ConflictIngredient> found) {
    final t = totalScore;
    return ShelfReport(
      typeCode: typeCode,
      matches: matches,
      totalScore:
          t == null ? null : (t - 7 * found.length).clamp(0, 100),
      missingIngredientIds: missingIngredientIds,
      conflicts: found,
    );
  }

  /// 내 BSTI 유형 코드. 검사 전이면 null.
  final String? typeCode;

  /// 담은 제품별 평가.
  final List<ProductMatch> matches;

  /// 화장대 총점 0~100. 평가 가능한 제품이 없으면 null.
  final int? totalScore;

  /// 내 유형의 권장 성분 중, 화장대의 어떤 제품에도 없는 것들 (BSTI 성분 id).
  /// 검사 전이면 비어 있다.
  final List<String> missingIngredientIds;

  bool get isEmpty => matches.isEmpty;

  /// 잘 맞는 제품 (80점 이상).
  List<ProductMatch> get goodMatches =>
      matches.where((m) => (m.score ?? -1) >= 80).toList();

  /// 다시 볼 제품 (50점 미만 — 주의 성분이 더 많다).
  List<ProductMatch> get poorMatches =>
      matches.where((m) => m.score != null && m.score! < 50).toList();

  /// 성분 정보가 없어 판단 못 한 제품.
  List<ProductMatch> get unknownMatches =>
      matches.where((m) => m.unknown).toList();

  /// 총평 한 줄.
  String get summary {
    if (typeCode == null) return 'BSTI 검사를 먼저 하면 적합도를 볼 수 있어요';
    if (matches.isEmpty) return '화장대에 제품을 담으면 적합도를 알려드려요';
    final t = totalScore;
    if (t == null) return '담은 제품에서 판단할 성분 정보를 찾지 못했어요';
    if (t >= 80) return '내 피부타입에 잘 맞는 제품 위주로 쓰고 계세요';
    if (t >= 50) return '대체로 무난하지만 일부는 다시 볼 필요가 있어요';
    return '내 피부타입과 어긋나는 제품이 많아요';
  }

  /// 총평 밑에 붙는 구체적인 설명들.
  ///
  /// "잘 맞아요" 한 줄로 끝내지 않고, 몇 개 중 몇 개가 맞는지 · 어떤 제품이
  /// 문제인지 · 뭐가 부족한지를 실제 계산값으로 풀어준다.
  /// (근거가 없는 말은 넣지 않는다 — 없으면 그 줄이 빠진다)
  List<String> get details {
    if (typeCode == null || matches.isEmpty) return const [];

    final lines = <String>[];
    final scored = matches.where((m) => m.score != null).length;

    if (scored > 0) {
      final good = goodMatches.length;
      lines.add('판단 가능한 제품 $scored개 중 $good개가 $typeCode 유형에 잘 맞아요');
    }

    final poor = poorMatches;
    if (poor.isNotEmpty) {
      final names = poor.map((m) => m.name).take(2).join(', ');
      final more = poor.length > 2 ? ' 외 ${poor.length - 2}개' : '';
      lines.add('$names$more 은(는) 주의 성분이 더 많아요');
    }

    final missing = missingIngredientIds.length;
    if (missing > 0) {
      lines.add('내 유형 권장 성분 $missing개가 화장대에 아직 없어요');
    }

    final unknown = unknownMatches.length;
    if (unknown > 0) {
      lines.add('$unknown개는 성분 정보가 없어 점수를 매기지 못했어요');
    }

    if (conflicts.isNotEmpty) {
      final names = conflicts.map((c) => c.nameKr).take(2).join(', ');
      lines.add('제품끼리 겹치는 규제 성분 ${conflicts.length}개 ($names…) — '
          '함께 쓰면 과할 수 있어 감점했어요');
    }

    return lines;
  }
}

/// 보고서 계산기.
///
/// 실제 BSTI 데이터로 계산한다 (점수를 지어내지 않는다).
///   제품의 성분 → 내 유형의 권장/주의 성분과 대조
///   적합도 = 권장 ÷ (권장 + 주의) × 100
///   총점 = 평가 가능한 제품들의 평균
///
/// 성분 정보가 없어 판단할 수 없으면 점수를 만들지 않고 null 로 둔다.
class ReportEngine {
  const ReportEngine._();

  /// [entries] 중 제품만 골라 평가한다.
  ///
  /// [ingredientIdsOf] 는 제품 id → BSTI 성분 id 목록을 주는 함수.
  /// (목데이터든 API든 이 함수만 갈아끼우면 된다)
  static ShelfReport build({
    required String? typeCode,
    required List<ShelfEntry> entries,
    required List<String> Function(int productId) ingredientIdsOf,
    Set<String> extraRecommendIds = const {},
  }) {
    final type = typeCode == null ? null : kBstiSkinTypes[typeCode];
    final products = entries.where((e) => e.isProduct).toList();

    // 피부고민 권장 성분(extraRecommendIds)은 유형과 무관하게 반영한다 —
    // 검사 전이어도 고민만으로 부분 평가가 가능하다.
    if (type == null && extraRecommendIds.isEmpty) {
      return ShelfReport(
        typeCode: typeCode,
        matches: [
          for (final p in products)
            ProductMatch(
                name: p.name,
                productId: p.id,
                recommendHits: 0,
                avoidHits: 0,
                score: null),
        ],
        totalScore: null,
      );
    }

    final recommendIds = <String>{
      ...?type?.recommend.map((e) => e.ingredientId),
      ...extraRecommendIds, // 피부고민 권장 성분 합산
    };
    final avoidIds =
        type?.avoid.map((e) => e.ingredientId).toSet() ?? const <String>{};

    // 화장대 제품들이 통틀어 갖고 있는 성분 (부족분 계산용).
    final owned = <String>{};

    final matches = <ProductMatch>[];
    for (final p in products) {
      final ids = ingredientIdsOf(p.id).toSet();
      owned.addAll(ids);
      final recMatched = ids.intersection(recommendIds).toList()..sort();
      final avoMatched = ids.intersection(avoidIds).toList()..sort();
      final rec = recMatched.length;
      final avo = avoMatched.length;
      final total = rec + avo;

      matches.add(ProductMatch(
        name: p.name,
        productId: p.id,
        recommendHits: rec,
        avoidHits: avo,
        recommendIds: recMatched,
        avoidIds: avoMatched,
        // 근거가 없으면 점수를 만들지 않는다.
        score: total == 0 ? null : (rec / total * 100).round(),
      ));
    }

    final scored = matches.where((m) => m.score != null).toList();
    final total = scored.isEmpty
        ? null
        : (scored.map((m) => m.score!).reduce((a, b) => a + b) / scored.length)
            .round();

    // 권장 성분인데 화장대 어디에도 없는 것 = 부족 성분.
    // (유형 데이터의 sortOrder 순서를 그대로 따른다 — 중요한 것부터)
    final missing = [
      if (type != null)
        for (final link in type.recommend)
          if (!owned.contains(link.ingredientId)) link.ingredientId,
    ];

    return ShelfReport(
      typeCode: typeCode,
      matches: matches,
      totalScore: total,
      missingIngredientIds: missing,
    );
  }
}

/// 화장대 제품 여러 개에 겹치는 규제 성분 하나.
class ConflictIngredient {
  const ConflictIngredient({
    required this.nameKr,
    required this.serverIngredientId,
    required this.productNames,
  });

  final String nameKr;

  /// 서버 성분 id — 성분 해설(①) 조회용.
  final int serverIngredientId;

  /// 이 성분이 든 화장대 제품 이름들 (2개 이상).
  final List<String> productNames;
}
