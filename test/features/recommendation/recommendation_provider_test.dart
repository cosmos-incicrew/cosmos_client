// 맞춤 추천 검증 (가짜 저장소 기반).
//
// 피부유형·피부고민·기피성분이 실제로 반영되는지,
// 근거 문구가 "반영한 것만" 말하는지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/onboarding/data/skin_concern.dart';
import 'package:cosmos_app/features/recommendation/data/recommendation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_repositories.dart';

void main() {
  ProviderContainer make() {
    final c = ProviderContainer(overrides: fakeRepos);
    addTearDown(c.dispose);
    return c;
  }

  test('카테고리별로 묶여 나온다', () async {
    final c = make();
    final result = await c.read(recommendationProvider.future);

    // 가짜 데이터는 크림 1개 + 토너 1개.
    expect(result.byCategory.keys, containsAll(['크림', '토너']));
  });

  test('아무 정보도 없으면 근거를 지어내지 않는다', () async {
    final c = make();
    final result = await c.read(recommendationProvider.future);

    expect(result.basis.isEmpty, isTrue);
    expect(result.basis.typeCode, isNull);
    expect(result.basis.concernLabels, isEmpty);
  });

  test('검사·고민·기피가 근거에 그대로 반영된다', () async {
    final c = make();
    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    c.read(userProfileProvider.notifier)
        .save(const UserProfile(concerns: {SkinConcern.acne}));
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 101,
          name: '글리세린',
          isProduct: false,
          kind: PreferenceKind.dislike,
        ));

    final result = await c.read(recommendationProvider.future);
    expect(result.basis.typeCode, 'OSPW');
    expect(result.basis.concernLabels, contains('여드름·뾰루지'));
    expect(result.basis.avoidCount, 1);
  });

  test('기피 성분이 든 제품은 추천에서 빠진다', () async {
    final c = make();
    // 글리세린(101)은 테스트 수분크림(id 1)에 들어 있다.
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 101,
          name: '글리세린',
          isProduct: false,
          kind: PreferenceKind.dislike,
        ));

    final result = await c.read(recommendationProvider.future);
    final all = result.byCategory.values.expand((e) => e);
    expect(all.any((p) => p.id == 1), isFalse,
        reason: '기피 성분이 든 제품을 추천했다');
  });

  test('기피로 담은 제품 자체도 빠진다', () async {
    final c = make();
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 2,
          name: '테스트 진정토너',
          isProduct: true,
          kind: PreferenceKind.dislike,
        ));

    final result = await c.read(recommendationProvider.future);
    final all = result.byCategory.values.expand((e) => e);
    expect(all.any((p) => p.id == 2), isFalse);
  });

  test('내 고민에 맞는 성분이 많은 제품이 앞에 온다', () async {
    final c = make();
    // 민감성 → cica(병풀). 테스트 진정토너(id 2)가 그걸 갖고 있다.
    c.read(userProfileProvider.notifier)
        .save(const UserProfile(concerns: {SkinConcern.sensitivity}));

    final result = await c.read(recommendationProvider.future);
    final toners = result.byCategory['토너'] ?? const [];
    expect(toners.first.id, 2);
  });
}
