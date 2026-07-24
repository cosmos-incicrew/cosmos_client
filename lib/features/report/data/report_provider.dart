import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bsti/bsti.dart';
import '../../bsti/bsti_result_store.dart';
import '../../ingredient/data/ingredient_providers.dart';
import '../../my_shelf/data/shelf_preference.dart';
import '../../onboarding/data/profile_store.dart';
import '../../product/data/models/product.dart';
import '../../product/data/product_providers.dart';
import '../engine/report_engine.dart';

/// 화장대 종합 보고서 — 내 BSTI 유형 + 담은 제품으로 계산된다.
///
/// 검사를 다시 하거나 제품을 담으면 자동으로 다시 계산된다.
///
/// 설계 메모: [ReportEngine] 은 **동기 순수 함수로 유지한다.**
/// 성분 조회를 엔진 안으로 넣으면 제품마다 순차 왕복이 생기고,
/// 검증된 도메인 로직이 네트워크에 묶인다. 대신 여기서 성분 맵을
/// 한 번에(배치) 받아둔 뒤, 엔진에는 동기 콜백으로 넘긴다.
final shelfReportProvider = FutureProvider<ShelfReport>((ref) async {
  final typeCode = ref.watch(bstiResultProvider);
  final entries = ref.watch(shelfPreferenceProvider);
  final profile = ref.watch(userProfileProvider);

  final productIds =
      entries.where((e) => e.isProduct).map((e) => e.id).toList();

  // 담은 제품들의 BSTI 성분을 배치로 1회 조회.
  final byProduct = productIds.isEmpty
      ? const <int, List<String>>{}
      : await ref
          .watch(ingredientRepositoryProvider)
          .bstiIdsByProducts(productIds);

  // 피부고민에서 오는 권장 성분 — 유형 권장과 합쳐 점수에 반영된다.
  final concernIds = <String>{
    for (final c in profile.concerns) ...?kConcernIngredients[c],
  };
  // 기피 축 — 고민별 기피 사전 + 사용자가 화장대에서 기피로 담은 성분.
  // 사용자 기피는 이름 정확 일치로 BSTI id 에 잇는다 (애매한 매칭 금지).
  final dislikedNames = {
    for (final e in entries)
      if (!e.isProduct && e.kind == PreferenceKind.dislike) e.name,
  };
  final avoidIds = <String>{
    for (final c in profile.concerns) ...?kConcernAvoidIngredients[c],
    for (final ing in kBstiIngredients.values)
      if (dislikedNames.contains(ing.nameKo)) ing.id,
  };

  var report = ReportEngine.build(
    typeCode: typeCode,
    entries: entries,
    // 이미 받아둔 맵을 읽기만 하므로 여전히 동기 — 엔진 시그니처 그대로.
    ingredientIdsOf: (id) => byProduct[id] ?? const [],
    extraRecommendIds: concernIds,
    extraAvoidIds: avoidIds,
    concernLabels: [for (final c in profile.concerns) c.label],
  );

  // 제품 간 충돌 — 서버 비교 API 의 규제 정보로 계산한다.
  // 규제 성분이 **2개 이상 제품에 겹치면** 함께 쓸 때 과할 수 있는 조합.
  // 비교 실패는 보고서를 막지 않는다 (충돌 없음으로 표시될 뿐).
  if (productIds.length >= 2) {
    try {
      final cmp = await ref
          .watch(productRepositoryProvider)
          .compare(productIds.take(4).toList()); // 서버 제한 2~4개
      final nameOf = {
        for (final p in cmp.products) p.id: p.productName,
      };
      final conflicts = [
        for (final ing in cmp.ingredientPresence)
          if (ing.restrictions.isNotEmpty && ing.productIds.length >= 2)
            ConflictIngredient(
              nameKr: ing.nameKr,
              serverIngredientId: ing.ingredientId,
              productNames: [
                for (final pid in ing.productIds)
                  if (nameOf[pid] != null) nameOf[pid]!,
              ],
            ),
      ];
      if (conflicts.isNotEmpty) report = report.withConflicts(conflicts);
    } on Object {
      // 비교 실패 — 충돌 정보 없이 보고서 유지.
    }
  }

  return report;
});

/// 부족한 성분 하나 + 그 성분을 채워주는 추천 제품.
class ShelfSuggestion {
  const ShelfSuggestion({
    required this.ingredientName,
    required this.ingredientRole,
    required this.products,
    this.bstiId,
  });

  /// BSTI 사전 id — 근거(논문) 조회용.
  final String? bstiId;

  /// 부족한 성분 이름 (예: '세라마이드').
  final String ingredientName;

  /// 그 성분이 하는 일 (예: '장벽 복구·경피수분손실 감소'). 데이터에 없으면 null.
  final String? ingredientRole;

  /// 이 성분을 가진 제품들 (이미 담은 건 빠진다).
  final List<Product> products;
}

/// 보고서 하단 "보충이 필요한 성분" — 성분 칩 목록.
///
/// 부족 성분(내 유형·고민 권장인데 화장대에 없는 것)을 최대 5개 보여준다.
/// 성분→제품 역조회 API 가 없으므로 제품은 붙이지 않는다 — 실제 제품 연결은
/// 화면의 "제품 추천 받기"가 추천 API 의 top_products 로 잇는다.
/// **사용자가 기피로 담은 성분은 추천에서 제외한다.**
final shelfSuggestionsProvider =
    FutureProvider<List<ShelfSuggestion>>((ref) async {
  final report = await ref.watch(shelfReportProvider.future);
  final entries = ref.watch(shelfPreferenceProvider);

  // 기피로 담은 성분 이름 — 이 성분은 부족해도 권하지 않는다.
  final dislikedNames = {
    for (final e in entries)
      if (!e.isProduct && e.kind == PreferenceKind.dislike) e.name,
  };

  final suggestions = <ShelfSuggestion>[];
  for (final bstiId in report.missingIngredientIds) {
    final info = kBstiIngredients[bstiId];
    if (info == null) continue;
    if (dislikedNames.contains(info.nameKo)) continue; // 기피 성분 제외

    suggestions.add(ShelfSuggestion(
      ingredientName: info.nameKo,
      ingredientRole: info.role,
      products: const [],
      bstiId: bstiId,
    ));
    if (suggestions.length == 5) break; // 화면엔 최대 5개
  }
  return suggestions;
});
