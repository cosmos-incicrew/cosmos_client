// BSTI 성분→유형 매칭 검증 — 실제 kBstiSkinTypes 권장 성분과 대조.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('빈 입력이면 null', () {
    expect(BstiEngine.matchTypeByIngredients([]), isNull);
  });

  test('아무 유형도 권장하지 않는 성분이면 null', () {
    // 존재하지 않는 성분 id.
    expect(BstiEngine.matchTypeByIngredients(['__nope__']), isNull);
  });

  test('세라마이드(cera)를 권장하는 유형으로 매칭된다', () {
    final type = BstiEngine.matchTypeByIngredients(['cera']);
    expect(type, isNotNull);
    // 매칭된 유형의 권장 목록에 실제로 cera가 있어야 한다.
    final ids = type!.recommend.map((e) => e.ingredientId);
    expect(ids, contains('cera'));
  });

  test('여러 성분이 겹칠수록 더 많이 겹치는 유형이 선택된다', () {
    // 건성·민감 계열 성분들(cera, ha, panth)은 DS/DR 유형에서 함께 권장된다.
    final type = BstiEngine.matchTypeByIngredients(['cera', 'ha', 'panth']);
    expect(type, isNotNull);
    final ids = type!.recommend.map((e) => e.ingredientId).toSet();
    final overlap = {'cera', 'ha', 'panth'}.intersection(ids).length;
    // 선택된 유형은 최소 2개 이상 겹쳐야 (최다 매칭).
    expect(overlap, greaterThanOrEqualTo(2));
  });
}
