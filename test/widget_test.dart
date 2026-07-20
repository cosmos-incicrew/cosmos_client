import 'package:cosmos_app/features/ingredient/data/models/ingredient.dart';
import 'package:cosmos_app/features/product/data/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Product', () {
    test('fromJson 파싱 (RAG product 스키마)', () {
      final p = Product.fromJson({
        'product_id': 77,
        'product_name': 'OO 세럼',
        'main_category': '스킨케어',
        'sub_category': '세럼/앰플',
        'ingredient_ids': [1024, 302],
      });
      expect(p.id, 77);
      expect(p.name, 'OO 세럼');
      expect(p.ingredientIds, [1024, 302]);
    });

  });

  group('Ingredient', () {
    test('결측 필드는 null로 파싱된다 (빈 문자열 아님)', () {
      final ing = Ingredient.fromJson({
        'ingredient_id': 1024,
        'name_eng': '1,2-HEXANEDIOL',
        'name_kor': '1,2-헥산다이올',
        // efficacy, product_property 등은 결측
      });
      expect(ing.id, 1024);
      expect(ing.nameKor, '1,2-헥산다이올');
      expect(ing.efficacy, isNull);
      expect(ing.productProperty, isNull);
    });

    test('safety_note가 null이면 "안전성 확인 불가"로 표시된다', () {
      const r = IngredientRestriction(safetyNote: null);
      expect(r.safetyDisplay, '안전성 확인 불가');
    });

    test('name_kor가 없으면 displayName은 영문으로 폴백', () {
      const ing = Ingredient(id: 1, nameKor: null, nameEng: 'RETINOL');
      expect(ing.displayName, 'RETINOL');
    });
  });
}
