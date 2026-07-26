import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bsti/bsti.dart';
import '../../bsti/bsti_result_store.dart';
import '../../ingredient/data/ingredient_providers.dart';
import '../../my_shelf/data/shelf_preference.dart';
import '../../onboarding/data/profile_store.dart';
import '../../product/data/models/product.dart';
import '../../product/data/product_providers.dart';

/// 추천 근거 — 화면 상단에 "무엇을 반영했는지" 그대로 보여준다.
///
/// 반영한 것만 담는다. BSTI를 안 했으면 [typeCode] 가 null 이고,
/// 화면도 그 말을 하지 않는다.
class RecommendationBasis {
  const RecommendationBasis({
    required this.typeCode,
    required this.concernLabels,
    required this.avoidCount,
  });

  final String? typeCode;
  final List<String> concernLabels;
  final int avoidCount;

  bool get isEmpty =>
      typeCode == null && concernLabels.isEmpty && avoidCount == 0;
}

/// 카테고리별 추천 결과 + 근거.
class RecommendationResult {
  const RecommendationResult({required this.byCategory, required this.basis});

  /// 소분류(토너·크림…) → 제품들. 나에게 맞는 순으로 정렬돼 있다.
  final Map<String, List<Product>> byCategory;
  final RecommendationBasis basis;
}

/// 1단계(빠름) — 제품 풀: 씨앗 검색만으로 카테고리 그룹을 만든다 (1~2초).
///
/// 매칭 정렬(2단계)이 끝나기 전에도 화면이 카테고리를 먼저 띄울 수 있도록
/// 단계를 분리했다 — 시연·체감 속도용. 전체 제품 목록 API 가 서버에 없어서
/// (listAll 은 스텁 — TODO(BE): GET /products) 씨앗 검색으로 실데이터를 채운다.
final recommendationPoolProvider =
    FutureProvider<RecommendationResult>((ref) async {
  final typeCode = ref.watch(bstiResultProvider);
  final profile = ref.watch(userProfileProvider);
  final shelf = ref.watch(shelfPreferenceProvider);

  // 화장대에서 "기피"로 담은 성분·제품은 추천에서 뺀다.
  final avoidIngredientIds = shelf
      .where((e) => !e.isProduct && e.kind == PreferenceKind.dislike)
      .map((e) => e.id)
      .toSet();
  final avoidProductIds = shelf
      .where((e) => e.isProduct && e.kind == PreferenceKind.dislike)
      .map((e) => e.id)
      .toSet();

  final basis = RecommendationBasis(
    typeCode: typeCode,
    concernLabels: profile.concerns.map((c) => c.label).toList(),
    avoidCount: avoidIngredientIds.length,
  );

  const seeds = ['크림', '토너', '세럼', '로션', '에센스', '선크림', '클렌징', '마스크팩'];
  final repo = ref.watch(productRepositoryProvider);
  final seedResults = await Future.wait([
    for (final seed in seeds) repo.search(seed),
  ]);
  final byId = <int, Product>{};
  for (final list in seedResults) {
    for (final p in list.take(6)) {
      byId.putIfAbsent(p.id, () => p);
    }
  }

  final map = <String, List<Product>>{};
  for (final p in byId.values) {
    final category = p.subCategory;
    if (category == null) continue;
    if (avoidProductIds.contains(p.id)) continue;
    if (p.ingredientIds.any(avoidIngredientIds.contains)) continue;
    map.putIfAbsent(category, () => []).add(p);
  }
  return RecommendationResult(byCategory: map, basis: basis);
});

/// 2단계(느림) — 매칭 hit: 제품 id → 내가 찾는 성분과 겹치는 수.
///
/// 제품별 성분 조회가 많아 수 초 걸린다. 화면은 이게 끝나기 전엔 씨앗 순서로
/// 보여주다가, 도착하면 정렬만 갱신한다. 세션 캐시 — 재진입 시 재계산 없음.
final recommendationHitsProvider = FutureProvider<Map<int, int>>((ref) async {
  final pool = await ref.watch(recommendationPoolProvider.future);
  final typeCode = ref.watch(bstiResultProvider);
  final profile = ref.watch(userProfileProvider);

  // 내가 찾는 BSTI 성분 = 내 유형 권장 + 내 고민에 맞는 성분.
  final wanted = <String>{
    ...?kBstiSkinTypes[typeCode]?.recommend.map((e) => e.ingredientId),
    for (final c in profile.concerns) ...?kConcernIngredients[c],
  };
  if (wanted.isEmpty) return const {};

  final ids = [
    for (final list in pool.byCategory.values)
      for (final p in list) p.id,
  ];
  final bstiByProduct =
      await ref.watch(ingredientRepositoryProvider).bstiIdsByProducts(ids);
  return {
    for (final id in ids)
      id: (bstiByProduct[id] ?? const []).where(wanted.contains).length,
  };
});

/// hit 수 기준으로 카테고리 안을 정렬한 사본. (동점이면 원래 순서 유지)
RecommendationResult sortRecommendationByHits(
  RecommendationResult pool,
  Map<int, int> hits,
) {
  if (hits.isEmpty) return pool;
  final byCategory = <String, List<Product>>{};
  for (final entry in pool.byCategory.entries) {
    final list = [...entry.value];
    list.sort((a, b) => (hits[b.id] ?? 0).compareTo(hits[a.id] ?? 0));
    byCategory[entry.key] = list;
  }
  return RecommendationResult(byCategory: byCategory, basis: pool.basis);
}

/// 맞춤 추천 최종본 — 내 피부유형 + 피부고민 + 기피성분을 반영해 정렬 완료.
///
/// 점수를 지어내지 않는다. "내가 찾는 성분과 몇 개나 겹치는가"로만 정렬한다.
final recommendationProvider =
    FutureProvider<RecommendationResult>((ref) async {
  final pool = await ref.watch(recommendationPoolProvider.future);
  final hits = await ref.watch(recommendationHitsProvider.future);
  return sortRecommendationByHits(pool, hits);
});
