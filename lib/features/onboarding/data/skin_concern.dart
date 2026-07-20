/// 피부고민 항목.
///
/// 코드(code)는 저장·API용, 라벨(label)은 화면 표시용이다.
/// 사용자에게는 "미백"처럼 한글만 보이고, 코드는 밖으로 드러내지 않는다.
enum SkinConcern {
  pores('pores', '모공'),
  brightening('brightening', '미백'),
  wrinkles('wrinkles', '주름'),
  acne('acne', '여드름·뾰루지'),
  redness('redness', '붉어짐·홍조'),
  dryness('dryness', '과각질·악건성'),
  sensitivity('sensitivity', '민감성'),
  sagging('sagging', '피부처짐·탄력저하');

  const SkinConcern(this.code, this.label);

  /// 저장·전송용 코드 (백엔드 붙을 때 이 값을 그대로 쓴다).
  final String code;

  /// 화면에 보이는 한글 이름.
  final String label;

  /// 코드로 항목 찾기. 없으면 null.
  static SkinConcern? fromCode(String code) {
    for (final c in SkinConcern.values) {
      if (c.code == code) return c;
    }
    return null;
  }
}
