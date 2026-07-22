// 서버 성분 이름 → BSTI id 매칭 검증.
//
// 이 매칭이 보고서 적합도의 근간이다 (서버엔 매핑이 없어 프론트가 잇는다).
// 틀린 매칭은 틀린 점수가 되므로, 정확 일치만 인정하는지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/bsti/bsti_name_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BSTI 성분 34개 전부 자기 한글명으로 풀린다', () {
    for (final ing in kBstiIngredients.values) {
      expect(bstiIdForNames(nameKr: ing.nameKo), ing.id,
          reason: '${ing.nameKo} 이 자기 id 로 안 풀림');
    }
  });

  test('INCI 영문명으로도 풀린다 (대소문자 무시)', () {
    for (final ing in kBstiIngredients.values) {
      final inci = ing.inci;
      if (inci == null) continue;
      expect(bstiIdForNames(nameEn: inci.toUpperCase()), ing.id,
          reason: '$inci (대문자) 가 안 풀림');
    }
  });

  test('부분일치는 매칭하지 않는다 — 틀린 점수 방지', () {
    // "Glycerin" 사전 항목이 있어도 "Glyceryl Stearate" 는 다른 성분이다.
    expect(bstiIdForNames(nameEn: 'Glyceryl Stearate'), isNull);
    expect(bstiIdForNames(nameKr: '글리세린유도체'), isNull);
  });

  test('모르는 이름은 null — 지어내지 않는다', () {
    expect(bstiIdForNames(nameKr: '존재하지않는성분'), isNull);
    expect(bstiIdForNames(nameEn: 'Unknownium'), isNull);
    expect(bstiIdForNames(), isNull);
  });

  test('한글명·INCI 가 사전 안에서 서로 겹치지 않는다', () {
    // 두 BSTI 성분이 같은 이름을 쓰면 매칭이 임의로 갈린다 — 사전 자체를 지킨다.
    final krNames = <String>{};
    final enNames = <String>{};
    for (final ing in kBstiIngredients.values) {
      expect(krNames.add(ing.nameKo), isTrue,
          reason: '한글명 중복: ${ing.nameKo}');
      final inci = ing.inci?.toLowerCase();
      if (inci != null) {
        expect(enNames.add(inci), isTrue, reason: 'INCI 중복: $inci');
      }
    }
  });
}
