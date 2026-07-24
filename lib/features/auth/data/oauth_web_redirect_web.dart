import 'package:web/web.dart' as web;

/// 현재 탭을 OAuth URL 로 이동시킨다.
///
/// supabase 의 signInWithOAuth 는 웹에서 `window.open(url, '_self',
/// 'noopener,noreferrer')` 를 쓰는데, features 인자(3번째)가 있으면 브라우저가
/// `_self` 를 무시하고 새 팝업 창을 연다. 게다가 URL 생성 await 뒤라 클릭
/// 제스처가 소실돼 팝업이 차단된다 — 그 결과 "버튼 눌러도 무반응"(구글)·
/// "스피너만 계속"(카카오)이 된다.
///
/// URL 만 받아 location 을 직접 바꾸면 팝업이 아니라 확실한 현재 탭
/// 리다이렉트가 된다. 복귀 후 세션은 restoreSession 이 잡는다.
void redirectToOAuthUrl(String url) {
  web.window.location.assign(url);
}
