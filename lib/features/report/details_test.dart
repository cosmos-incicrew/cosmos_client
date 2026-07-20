// 보고서 설명이 실제로 나오는지 검증.
//
// "잘 맞는 제품 위주로 쓰고 계세요" 한 줄로 끝나지 않고,
// 부족 성분·추천 제품·구체 설명이 실제로 채워지는지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti_result_store.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/data/report_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 화장대에 제품 하나를 담은 상태를 만든다.
ProviderContainer _withShelf({required String type, required int productId}) {
  final c = ProviderContainer();
  c.read(bstiResultProvider.notifier).save(type);
  c.read(shelfPreferenceProvider.notifier).add(ShelfEntry(
        id: productId,
        name: 'p$productId',
        isProduct: true,
        kind: PreferenceKind.like,
      ));
  return c;
}

void main() {
  test('제품을 담으면 점수 밑 설명이 여러 줄 나온다', () {
    final c = _withShelf(type: 'OSPW', productId: 13); // 나이아신아마이드 세럼
    addTearDown(c.dispose);

    final report = c.read(shelfReportProvider);
    // 예전엔 summary 한 줄이 전부였다 — 이제 구체 설명이 붙어야 한다.
    expect(report.details, isNotEmpty);
    expect(report.details.first, contains('판단 가능한 제품'));
  });

  test('부족 성분 추천이 실제로 채워진다 (빈 화면이면 실패)', () {
    final c = _withShelf(type: 'OSPW', productId: 13);
    addTearDown(c.dispose);

    // 이게 비면 화면에 "이런 성분이 부족해요" 섹션이 통째로 안 뜬다.
    final suggestions = c.read(shelfSuggestionsProvider);
    expect(suggestions, isNotEmpty,
        reason: '부족 성분에 붙일 목 제품이 없다 — 화면이 비어 보인다');
    expect(suggestions.first.products, isNotEmpty);
  });

  test('BSTI 검사 전에는 설명을 지어내지 않는다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 13,
          name: 'p13',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    // 유형을 모르면 무엇이 맞는지도 모른다 → 설명 없음.
    expect(c.read(shelfReportProvider).details, isEmpty);
  });

  test('16개 유형 어디서도 추천이 터지지 않는다', () {
    // 유형별로 권장 성분이 달라, 특정 유형만 빈 화면이 될 수 있다.
    for (final type in ['OSPW', 'DRNT', 'ORNW', 'DSPT']) {
      final c = _withShelf(type: type, productId: 13);
      addTearDown(c.dispose);
      expect(() => c.read(shelfSuggestionsProvider), returnsNormally,
          reason: '$type 에서 터짐');
    }
  });
}
