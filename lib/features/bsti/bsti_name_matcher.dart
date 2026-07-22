import 'bsti.dart';

/// 서버 성분 이름 → BSTI 성분 id 매칭.
///
/// 서버 DB에는 bsti_ingredient_id 매핑이 없다 (백엔드 결정: BSTI 는 프론트가
/// 다 들고 간다). 대신 BSTI 사전(kBstiIngredients)의 한글명·INCI 영문명과
/// 서버 성분의 name_kr / name_en 을 **정확히** 대조해 프론트에서 연결한다.
///
/// 부분일치를 쓰지 않는 이유: "Glycerin" 을 부분일치로 찾으면
/// "Glyceryl Stearate" 같은 다른 성분이 걸린다. 틀린 매칭으로 점수를
/// 만드느니 놓치는 게 낫다 — 놓치면 "판단 정보 부족"으로 뜰 뿐이다.
String? bstiIdForNames({String? nameKr, String? nameEn}) {
  final kr = nameKr?.trim();
  final en = nameEn?.trim().toLowerCase();

  for (final ing in kBstiIngredients.values) {
    if (kr != null && kr.isNotEmpty && kr == ing.nameKo) return ing.id;
    final inci = ing.inci?.toLowerCase();
    if (en != null && en.isNotEmpty && inci != null && en == inci) {
      return ing.id;
    }
  }
  return null;
}
