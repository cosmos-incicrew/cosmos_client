// 테스트용 가짜 저장소.
//
// 실제 데이터는 백엔드가 준다. 테스트는 화면 동작만 보면 되므로
// 여기 작은 샘플을 두고 저장소 프로바이더를 override 해서 쓴다.
// (앱 코드에는 목데이터를 두지 않는다 — lib/ 은 깨끗하게 유지)
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/ingredient/data/ingredient_providers.dart';
import 'package:cosmos_app/features/ingredient/data/ingredient_repository.dart';
import 'package:cosmos_app/features/ingredient/data/models/ingredient.dart';
import 'package:cosmos_app/features/ingredient/data/models/ingredient_insight.dart';
import 'package:cosmos_app/features/onboarding/data/profile_repository.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/product/data/models/product.dart';
import 'package:cosmos_app/features/product/data/models/product_compare.dart';
import 'package:cosmos_app/features/product/data/product_providers.dart';
import 'package:cosmos_app/features/product/data/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const testProducts = <Product>[
  Product(
    id: 1,
    name: '테스트 수분크림',
    brand: '테스트브랜드',
    mainCategory: '스킨케어',
    subCategory: '크림',
    ingredientIds: [101, 102],
  ),
  Product(
    id: 2,
    name: '테스트 진정토너',
    brand: '테스트브랜드',
    mainCategory: '스킨케어',
    subCategory: '토너',
    ingredientIds: [103],
  ),
];

const testIngredients = <Ingredient>[
  Ingredient(
    id: 101,
    nameKor: '글리세린',
    nameEng: 'Glycerin',
    efficacy: '수분 공급',
    bstiIngredientId: 'gly',
  ),
  Ingredient(
    id: 102,
    nameKor: '세라마이드',
    nameEng: 'Ceramide NP',
    efficacy: '장벽 복구',
    bstiIngredientId: 'cera',
  ),
  Ingredient(
    id: 103,
    nameKor: '병풀추출물',
    nameEng: 'Centella Asiatica Extract',
    efficacy: '진정',
    bstiIngredientId: 'cica',
  ),
];

class FakeProductRepository implements ProductRepository {
  const FakeProductRepository();

  @override
  Future<List<Product>> search(String query) async {
    if (query.isEmpty) return const [];
    final q = query.toLowerCase();
    return testProducts
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.brand ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<Product>> listAll() async => testProducts;

  /// 실제 백엔드처럼 제품 → 성분 id 목록 (배합 순서 유지).
  @override
  Future<List<int>> getIngredientIds(int productId) async =>
      testProducts.where((p) => p.id == productId).firstOrNull?.ingredientIds ??
      const [];

  @override
  Future<List<Product>> getByIngredient(int ingredientId) async =>
      testProducts.where((p) => p.ingredientIds.contains(ingredientId)).toList();

  /// 실제 서버처럼 성분 포함 범위(all/partial/single)를 계산한다.
  @override
  Future<ProductCompareResult> compare(List<int> productIds) async {
    final picked =
        testProducts.where((p) => productIds.contains(p.id)).toList();

    // 성분 id → 포함 제품 id 목록.
    final byIngredient = <int, List<int>>{};
    for (final p in picked) {
      for (final id in p.ingredientIds) {
        byIngredient.putIfAbsent(id, () => []).add(p.id);
      }
    }

    PresenceType typeOf(int count) {
      if (count == picked.length) return PresenceType.all;
      if (count > 1) return PresenceType.partial;
      return PresenceType.single;
    }

    return ProductCompareResult(
      products: [
        for (final p in picked)
          ComparedProduct(id: p.id, productName: p.name),
      ],
      ingredientPresence: [
        for (final e in byIngredient.entries)
          IngredientPresence(
            ingredientId: e.key,
            nameKr: testIngredients
                    .where((i) => i.id == e.key)
                    .firstOrNull
                    ?.nameKor ??
                '',
            productIds: e.value,
            presenceType: typeOf(e.value.length),
          ),
      ],
      ingredientIds: byIngredient.keys.toList(),
    );
  }

  @override
  Future<List<Product>> findByBstiIngredient(
    String bstiId, {
    Set<int> exclude = const {},
    int limit = 2,
  }) async {
    final matched = <Product>[];
    for (final p in testProducts) {
      if (exclude.contains(p.id)) continue;
      final has = p.ingredientIds.any((id) =>
          testIngredients
              .where((i) => i.id == id)
              .firstOrNull
              ?.bstiIngredientId ==
          bstiId);
      if (has) matched.add(p);
      if (matched.length == limit) break;
    }
    return matched;
  }
}

class FakeIngredientRepository implements IngredientRepository {
  const FakeIngredientRepository();

  @override
  Future<Ingredient?> findByExactName(String nameKo) async => null;

  @override
  Future<List<Ingredient>> search(String query) async {
    if (query.isEmpty) return const [];
    final q = query.toLowerCase();
    return testIngredients
        .where((i) =>
            (i.nameKor ?? '').toLowerCase().contains(q) ||
            i.nameEng.toLowerCase().contains(q))
        .toList();
  }

  /// 요청한 [ids] 순서를 그대로 지킨다 (실제 구현도 이래야 한다).
  @override
  Future<List<Ingredient>> getByIds(List<int> ids) async => [
        for (final id in ids)
          ...testIngredients.where((i) => i.id == id),
      ];

  /// ① 성분 해설 — 아는 성분은 ok, 모르면 실서버처럼 "확인 불가".
  @override
  Future<IngredientDetail> getDetail(int ingredientId) async {
    final ing = testIngredients.where((i) => i.id == ingredientId).firstOrNull;
    if (ing == null) {
      return IngredientDetail(
        status: InsightStatus.unavailable,
        ingredientId: ingredientId,
        reason: '테스트 데이터에 없는 성분',
      );
    }
    return IngredientDetail(
      status: InsightStatus.ok,
      ingredientId: ing.id,
      name: ing.nameKor,
      body: '${ing.displayName} 은(는) ${ing.efficacy ?? '정보 없음'} 에 쓰인다.',
      safety: '자극이 적은 편입니다',
    );
  }

  /// ② 제품 요약 — 배합순 앞 3개를 대표성분으로 (실서버와 같은 규칙).
  @override
  Future<ProductSummary> getProductSummary(List<int> ingredientIds) async {
    final tops = [
      for (final id in ingredientIds.take(3))
        TopIngredient(
          ingredientId: id,
          name: testIngredients.where((i) => i.id == id).firstOrNull?.nameKor,
        ),
    ];
    return ProductSummary(
      status: tops.isEmpty ? InsightStatus.unavailable : InsightStatus.ok,
      topIngredients: tops,
      summary: tops.isEmpty ? null : '보습 성분 위주로 구성된 제품입니다.\n주의: 테스트 요약입니다.',
    );
  }

  /// ③ 비교 해설.
  @override
  Future<ComparisonSummary> getComparisonSummary(
    ProductCompareResult compareResult,
  ) async {
    return ComparisonSummary(
      status: InsightStatus.ok,
      summary: '${compareResult.products.length}개 제품의 성분 구성을 비교한 테스트 해설입니다.',
    );
  }

  @override
  Future<Map<int, List<String>>> bstiIdsByProducts(
    List<int> productIds,
  ) async {
    final out = <int, List<String>>{};
    for (final pid in productIds) {
      final p = testProducts.where((e) => e.id == pid).firstOrNull;
      if (p == null) continue;
      out[pid] = [
        for (final id in p.ingredientIds)
          ...testIngredients
              .where((i) => i.id == id)
              .map((i) => i.bstiIngredientId)
              .whereType<String>(),
      ];
    }
    return out;
  }
}

/// 서버에 안 나가는 프로필 저장소.
///
/// BSTI 저장이 프로필 POST 를 타므로, 이게 없으면 테스트가 실제 HTTP 를 시도한다.
class FakeProfileRepository implements ProfileRepository {
  const FakeProfileRepository();

  @override
  Future<UserProfile?> fetch() async => null;

  @override
  Future<void> save(UserProfile profile) async {}

  @override
  Future<void> deleteAccount() async {}
}

/// 테스트용 저장소 override 모음. `ProviderContainer(overrides: fakeRepos)`.
final fakeRepos = <Override>[
  productRepositoryProvider.overrideWithValue(const FakeProductRepository()),
  ingredientRepositoryProvider
      .overrideWithValue(const FakeIngredientRepository()),
  profileRepositoryProvider.overrideWithValue(const FakeProfileRepository()),
];
