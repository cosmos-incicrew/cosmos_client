// 프로필 저장 + 고민→성분 매핑 검증.
//
// 온보딩에서 고른 피부고민이 실제로 저장되고, 추천이 쓸 수 있는
// BSTI 성분 id로 이어지는지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/onboarding/data/skin_concern.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('처음엔 비어 있다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final p = c.read(userProfileProvider);
    expect(p.concerns, isEmpty);
    expect(p.hasConcerns, isFalse);
  });

  test('고른 피부고민이 저장된다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(userProfileProvider.notifier).save(
      nickname: '테스트',
      age: 28,
      gender: 'female',
      concerns: {SkinConcern.acne, SkinConcern.pores},
    );

    final p = c.read(userProfileProvider);
    expect(p.nickname, '테스트');
    expect(p.age, 28);
    expect(p.hasConcerns, isTrue);
    expect(p.concerns, containsAll([SkinConcern.acne, SkinConcern.pores]));
  });

  test('고민 8개 전부 BSTI 성분과 연결돼 있다', () {
    // 매핑이 비면 추천이 조용히 아무것도 반영 못 한다.
    for (final concern in SkinConcern.values) {
      final ids = kConcernIngredients[concern];
      expect(ids, isNotNull, reason: '${concern.label} 매핑 없음');
      expect(ids, isNotEmpty, reason: '${concern.label} 매핑 비어 있음');
    }
  });

  test('매핑된 성분 id가 전부 실제 BSTI 데이터에 있다', () {
    // 지어낸 id를 쓰면 추천이 조용히 비어버린다 — 그걸 막는다.
    for (final entry in kConcernIngredients.entries) {
      for (final id in entry.value) {
        expect(kBstiIngredients.containsKey(id), isTrue,
            reason: '${entry.key.label} → 없는 성분 id "$id"');
      }
    }
  });

  test('clear 하면 비워진다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(userProfileProvider.notifier).save(concerns: {SkinConcern.acne});
    c.read(userProfileProvider.notifier).clear();
    expect(c.read(userProfileProvider).concerns, isEmpty);
  });
}
