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
/// 서버(식약처 표기)와 BSTI 사전 표기가 다른 경우의 **검증된** 이명.
///
/// 실서버 데이터로 확인된 것만 넣는다 — 추측으로 넣으면 틀린 매칭이
/// 틀린 적합도 점수가 된다. (예: 코코넛'추출물'을 오일로 취급하면
/// 기피 판정이 잘못 잡힘 → 확인 전엔 놓치는 쪽을 택한다)
const Map<String, List<String>> kBstiServerAliases = {
  // 사전 '저농도 레티날/바쿠치올' — 서버 표기는 '레틴알', '바쿠치올' 두 성분.
  'retal': ['레틴알', '바쿠치올'],
};

String? bstiIdForNames({String? nameKr, String? nameEn}) {
  final kr = nameKr?.trim();
  final en = nameEn?.trim().toLowerCase();

  for (final ing in kBstiIngredients.values) {
    if (kr != null && kr.isNotEmpty && kr == ing.nameKo) return ing.id;
    final inci = ing.inci?.toLowerCase();
    if (en != null && en.isNotEmpty && inci != null && en == inci) {
      return ing.id;
    }
    // 검증된 서버 이명 (한글명 정확 일치만).
    final aliases = kBstiServerAliases[ing.id];
    if (aliases != null && kr != null && aliases.contains(kr)) return ing.id;
  }
  return null;
}
