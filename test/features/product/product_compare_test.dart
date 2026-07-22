// 다중 제품 비교 응답 파싱 검증.
//
// 노션 "API JSON" 명세서의 성공 응답 예시를 **그대로** 넣고 파싱한다.
// 명세서와 모델이 어긋나면 여기서 잡힌다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/product/data/models/product_compare.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_repositories.dart';

void main() {
  // 명세서의 성공 응답 예시 원문.
  const specExample = {
    'products': [
      {'id': 101, 'product_name': '제품 A'},
      {'id': 102, 'product_name': '제품 B'},
    ],
    'ingredient_presence': [
      {
        'ingredient_id': 1,
        'name_kr': '정제수',
        'product_ids': [101, 102],
        'presence_type': 'all',
        'restrictions': <Map<String, dynamic>>[],
      },
      {
        'ingredient_id': 2,
        'name_kr': '글리세린',
        'product_ids': [101],
        'presence_type': 'single',
        'restrictions': [
          {
            'restriction_id': 10,
            'regulate_type': '한도',
            'provis_atrcl': '사용 조건',
            'limit_cond': '배합 한도',
            'is_registered_korea': true,
          },
        ],
      },
    ],
    'ingredient_ids': [1, 2],
  };

  test('명세서 예시 JSON 이 그대로 파싱된다', () {
    final result = ProductCompareResult.fromJson(specExample);

    expect(result.products, hasLength(2));
    expect(result.products.first.productName, '제품 A');

    expect(result.ingredientPresence, hasLength(2));
    final water = result.ingredientPresence[0];
    expect(water.nameKr, '정제수');
    expect(water.presenceType, PresenceType.all);
    expect(water.restrictions, isEmpty);

    final glycerin = result.ingredientPresence[1];
    expect(glycerin.presenceType, PresenceType.single);
    expect(glycerin.restrictions, hasLength(1));
    expect(glycerin.restrictions.first.regulateType, '한도');
    expect(glycerin.restrictions.first.isRegisteredKorea, isTrue);

    // 후속 요청엔 최상위 ingredient_ids 를 그대로 쓴다 (명세서 지시).
    expect(result.ingredientIds, [1, 2]);
  });

  test('restrictions 의 null 필드는 null 로 남는다 (빈 문자열 아님)', () {
    final r = CompareRestriction.fromJson(const {'restriction_id': 1});
    expect(r.regulateType, isNull);
    expect(r.isRegisteredKorea, isNull);
  });

  test('모르는 presence_type 이 와도 파싱이 터지지 않는다', () {
    // 서버가 값을 추가해도 (예: MVP 이후 확장) 앱이 죽지 않아야 한다.
    expect(PresenceType.fromCode('whatever'), PresenceType.single);
  });

  test('가짜 저장소 — 2개 비교에서 all/single 이 맞게 갈린다', () async {
    const repo = FakeProductRepository();
    // 테스트 데이터: 제품1=[101,102], 제품2=[103] → 공통 성분 없음.
    final result = await repo.compare([1, 2]);

    expect(result.products, hasLength(2));
    for (final p in result.ingredientPresence) {
      // 2개 비교에서는 partial 이 나올 수 없다 (명세서 기준표).
      expect(p.presenceType, isNot(PresenceType.partial));
      expect(p.presenceType, PresenceType.single);
    }
    // ingredient_ids 는 중복 없이 전체 성분.
    expect(result.ingredientIds.toSet().length, result.ingredientIds.length);
  });
}
