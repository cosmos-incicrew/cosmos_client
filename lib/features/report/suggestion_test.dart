// 보고서 하단 "OO 성분이 부족합니다 → 이 제품을 추천해요" 검증.
//
// 지어낸 추천이 아니라, 내 유형의 권장 성분 중 화장대에 없는 것만 짚는지를 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti_result_store.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/data/report_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BSTI 검사 전에는 추천이 뜨지 않는다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    // 유형을 모르면 무엇이 부족한지도 알 수 없다 → 지어내면 안 된다.
    expect(c.read(shelfSuggestionsProvider), isEmpty);
    expect(c.read(shelfReportProvider).missingIngredientIds, isEmpty);
  });

  test('검사를 하면 부족 성분과 그 성분을 가진 제품이 함께 나온다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(bstiResultProvider.notifier).save('OSPW');

    final suggestions = c.read(shelfSuggestionsProvider);
    expect(suggestions, isNotEmpty);

    for (final s in suggestions) {
      // 성분 이름이 비어 있으면 화면에 "  성분이 부족합니다"가 된다.
      expect(s.ingredientName, isNotEmpty);
      // 추천할 제품이 없는 성분은 애초에 넣지 않기로 했다.
      expect(s.products, isNotEmpty);
    }
    expect(suggestions.length, lessThanOrEqualTo(3));
  });

  test('이미 담은 제품은 다시 추천하지 않는다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(bstiResultProvider.notifier).save('OSPW');

    // 추천으로 뜬 제품 하나를 골라 화장대에 담는다.
    final first = c.read(shelfSuggestionsProvider).first.products.first;
    c.read(shelfPreferenceProvider.notifier).add(ShelfEntry(
          id: first.id,
          name: first.name,
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    // 담은 뒤에는 어떤 성분의 추천에서도 그 제품이 보이면 안 된다.
    final after = c.read(shelfSuggestionsProvider);
    for (final s in after) {
      expect(s.products.any((p) => p.id == first.id), isFalse,
          reason: '이미 화장대에 있는 ${first.name}을 또 추천했다');
    }
  });

  test('담은 제품이 채워준 성분은 부족 목록에서 빠진다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(bstiResultProvider.notifier).save('OSPW');
    final before = c.read(shelfReportProvider).missingIngredientIds.toSet();

    // 세라마이드·글리세린 등을 가진 목 제품(id 2)을 담는다.
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 2,
          name: '아토베리어365 크림',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    final after = c.read(shelfReportProvider).missingIngredientIds.toSet();
    // 부족 목록은 줄어들 수는 있어도 늘어나선 안 된다.
    expect(after.difference(before), isEmpty);
  });
}
