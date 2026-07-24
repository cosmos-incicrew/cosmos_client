/// 웹 전용 OAuth 리다이렉트 헬퍼 (스텁).
///
/// 네이티브 빌드에서는 이 스텁이 링크되며 호출되지 않는다 — 웹 분기(kIsWeb)
/// 안에서만 부른다. 실제 구현은 [oauth_web_redirect_web.dart] (조건부 import).
void redirectToOAuthUrl(String url) {
  throw UnsupportedError('redirectToOAuthUrl 은 웹에서만 사용됩니다.');
}
