/// 에셋 경로 상수.
///
/// 화면에서 `'assets/...'` 문자열을 직접 쓰지 않고 여기 상수를 참조한다.
/// 경로가 바뀌어도 이 파일만 고치면 된다. (폴더 구조는 assets/README.md)
class AppAssets {
  const AppAssets._();

  static const String _logo = 'assets/images/logo';
  static const String _social = 'assets/icons/social';
  static const String _home = 'assets/images/home';
  static const String _common = 'assets/icons/common';
  static const String _bstiIcon = 'assets/images/bsti/icon';

  /// 앱 오픈(스플래시) 메인 로고 — 움직이는 고양이 GIF.
  static const String logoFullAnimated = '$_logo/logo_full.gif';

  /// 시작 로고 정적 버전(PNG) — 고양이 캐릭터 + "예뻐지는 Space COSMOS".
  /// GIF를 못 쓰는 자리(썸네일 등)용 fallback.
  static const String logoFull = '$_logo/logo_full.png';

  /// 앱 상단(앱바)에 항상 유지되는 워드마크 — "COSMOS" + 별.
  static const String logoWordmark = '$_logo/logo_wordmark.png';

  // 소셜 로그인 정품 로고 (PNG). 파일을 assets/icons/social/ 에 넣으면 표시됨.
  static const String kakao = '$_social/kakao.png';
  static const String naver = '$_social/naver.png';
  static const String google = '$_social/google.png';
  static const String apple = '$_social/apple.png';

  // 홈 메뉴 이미지 (PNG). 없으면 화면에서 플레이스홀더로 대체됨.
  //
  // 캡션·타이틀·버튼이 이미지 안에 모두 그려져 있다. 따라서 위에 텍스트
  // 위젯을 얹지 않고, 이미지 한 장 전체를 탭 영역으로 쓴다.

  /// "내 화장대 점수는??" 배너 (타이틀·설명·START·고양이 포함).
  static const String homeShelfScoreBanner = '$_home/shelf_score_banner.png';

  /// BSTI — "16가지 피부 MBTI / 내 피부타입 검사".
  static const String homeBsti = '$_home/bsti.png';

  /// 내 화장대 — "내 화장대 만들기".
  static const String homeShelf = '$_home/my_shelf.png';

  /// My-Skin ITEM — "나와 베스트 궁합 제품 추천".
  static const String homeMyItem = '$_home/my_skin_item.png';

  /// 화장대 일러스트 — 현재 화면에서 미사용 (예비).
  static const String homeShelfMake = '$_home/shelf_make.png';

  // 프로필 성별 선택 고양이.
  static const String profileFemale = 'assets/images/profile/female.png';
  static const String profileMale = 'assets/images/profile/male.png';

  // 공용 픽셀 아이콘.
  static const String iconSearch = '$_common/search.png'; // 홈 검색창 돋보기
  static const String startButton = '$_common/start_button.png'; // START 버튼
  static const String tapFinger = '$_common/tap_finger.png'; // 누름 효과 손가락

  // BSTI 설문 진행바 고양이 마커.
  static const String progressCat = '$_bstiIcon/progress_cat.png';

  /// 권장성분 고양이 — 선호(초록) 표시에 함께 쓴다.
  static const String iconRecommend = '$_bstiIcon/recommend.png';

  /// 주의성분 고양이 — 기피(빨강) 표시에 함께 쓴다.
  static const String iconAvoid = '$_bstiIcon/avoid.png';

  /// BSTI 16개 유형 고양이가 모두 모인 이미지 (인트로 하단).
  static const String bstiAllTypes = 'assets/images/bsti/all_types.png';

  // 온보딩 슬라이드 일러스트.
  /// "내 피부고민과 화장품 등록하면" 슬라이드 — 화장품 고르는 우주 고양이.
  static const String onboardingShelf = 'assets/images/onboarding/shelf.png';

  /// "내 화장대 종합보고서까지" 슬라이드 — 보고서 체크하는 우주 고양이.
  static const String onboardingReport = 'assets/images/onboarding/report.png';
}
