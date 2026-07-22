import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'ingredient_repository.dart';
import 'models/ingredient.dart';

/// 성분 저장소. 테스트에서는 이 프로바이더를 override 해서 가짜를 넣는다.
final ingredientRepositoryProvider = Provider<IngredientRepository>((ref) {
  return IngredientRepository(ref.watch(dioProvider));
});

/// 성분 검색 결과. 검색어별로 캐시된다.
final ingredientSearchProvider =
    FutureProvider.family<List<Ingredient>, String>((ref, query) async {
  if (query.isEmpty) return const [];
  return ref.watch(ingredientRepositoryProvider).search(query);
});

/// 성분 id들을 쉼표로 이은 문자열(예: '101,102,103')로 조회.
///
/// 입력 순서가 그대로 유지된다 — 앞 3개가 "대표성분"으로 쓰인다.
///
/// family 키가 `List<int>` 가 아니라 String 인 이유: Dart 리스트는 동등성이
/// 아니라 동일성으로 비교돼서, build 마다 새 리스트가 만들어지면 캐시가 안 먹고
/// 매번 다시 조회한다. 문자열은 값으로 비교되므로 캐시가 정상 동작한다.
/// 호출부는 [ingredientIdsKey] 로 키를 만든다.
final ingredientsByIdsProvider =
    FutureProvider.family<List<Ingredient>, String>((ref, idsKey) async {
  if (idsKey.isEmpty) return const [];
  final ids = idsKey.split(',').map(int.parse).toList();
  return ref.watch(ingredientRepositoryProvider).getByIds(ids);
});

/// [ingredientsByIdsProvider] 용 캐시 키. 순서를 보존한다(정렬하지 않는다).
String ingredientIdsKey(List<int> ids) => ids.join(',');
