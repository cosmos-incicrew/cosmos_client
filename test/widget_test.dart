import 'package:cosmos_app/features/product/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('제품명으로 검색 필터가 동작한다', () {
    final results = sampleProducts
        .where((p) => p.name.contains('토너'))
        .toList();
    expect(results.length, 1);
    expect(results.first.id, '1');
  });

  test('성분명으로 검색 필터가 동작한다', () {
    final results = sampleProducts
        .where((p) => p.ingredients.any((i) => i.contains('나이아신아마이드')))
        .toList();
    expect(results.length, 2);
  });

  test('Product.fromJson 파싱', () {
    final p = Product.fromJson({
      'id': '99',
      'name': '테스트',
      'brand': 'cosmos',
      'ingredients': ['정제수'],
      'safety_score': 80,
    });
    expect(p.name, '테스트');
    expect(p.ingredients, ['정제수']);
    expect(p.safetyScore, 80);
  });
}
