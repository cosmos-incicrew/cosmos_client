// 보고서 흐름 검증 (가짜 저장소 기반).
//
// BSTI 결과 + 화장대 → 적합도 점수 · 부족 성분 · 추천 제품이
// 실제로 이어지는지 본다. 데이터는 test/support/fake_repositories.dart.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/data/report_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_repositories.dart';

void main() {
  ProviderContainer make() {
    final c = ProviderContainer(overrides: fakeRepos);
    addTearDown(c.dispose);
    return c;
  }

  test('BSTI 검사 전에는 점수를 지어내지 않는다', () async {
    final c = make();
    final report = await c.read(shelfReportProvider.future);

    expect(report.typeCode, isNull);
    expect(report.totalScore, isNull);
    expect(report.details, isEmpty);
    expect(report.missingIngredientIds, isEmpty);
  });

  test('검사 + 제품을 담으면 점수와 근거가 계산된다', () async {
    final c = make();
    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 2, // 병풀추출물(cica) — OSPW 권장 성분
          name: '테스트 진정토너',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    final report = await c.read(shelfReportProvider.future);
    expect(report.typeCode, 'OSPW');
    expect(report.matches, hasLength(1));
    // 권장 성분과 겹치므로 점수가 나와야 한다.
    expect(report.totalScore, isNotNull);
    expect(report.details, isNotEmpty);
  });

  test('부족 성분에는 그 성분을 가진 제품이 함께 붙는다', () async {
    final c = make();
    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');

    final suggestions = await c.read(shelfSuggestionsProvider.future);
    for (final s in suggestions) {
      expect(s.ingredientName, isNotEmpty);
      // 추천할 제품이 없는 성분은 아예 넣지 않기로 했다.
      expect(s.products, isNotEmpty);
    }
    expect(suggestions.length, lessThanOrEqualTo(3));
  });

  test('이미 담은 제품은 다시 추천하지 않는다', () async {
    final c = make();
    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');

    final before = await c.read(shelfSuggestionsProvider.future);
    if (before.isEmpty) return; // 추천이 없으면 검증할 것도 없다

    final first = before.first.products.first;
    c.read(shelfPreferenceProvider.notifier).add(ShelfEntry(
          id: first.id,
          name: first.name,
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    final after = await c.read(shelfSuggestionsProvider.future);
    for (final s in after) {
      expect(s.products.any((p) => p.id == first.id), isFalse,
          reason: '이미 화장대에 있는 ${first.name}을 또 추천했다');
    }
  });

  test('재검사하면 보고서가 다시 계산된다', () async {
    final c = make();
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 1,
          name: '테스트 수분크림',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    final first = await c.read(shelfReportProvider.future);

    await c.read(userProfileProvider.notifier).saveBstiType('DRNT');
    final second = await c.read(shelfReportProvider.future);

    expect(first.typeCode, 'OSPW');
    expect(second.typeCode, 'DRNT');
  });
}
