/// 앱 전역 인증 상태 모델.
enum AuthStatus { unknown, unauthenticated, guest, authenticated }

/// 로그인 방식.
enum AuthProvider { none, guest, kakao, google, apple }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.provider = AuthProvider.none,
    this.userId,
    this.displayName,
    this.onboarded = false,
  });

  final AuthStatus status;
  final AuthProvider provider;
  final String? userId;
  final String? displayName;

  /// 온보딩(프로필·피부고민 등록)을 마쳤는지.
  /// 로그인은 했지만 온보딩 전이면 홈이 아니라 온보딩으로 보낸다.
  final bool onboarded;

  bool get isSignedIn =>
      status == AuthStatus.authenticated || status == AuthStatus.guest;

  AuthState copyWith({
    AuthStatus? status,
    AuthProvider? provider,
    String? userId,
    String? displayName,
    bool? onboarded,
  }) {
    return AuthState(
      status: status ?? this.status,
      provider: provider ?? this.provider,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  static const unauthenticated = AuthState(
    status: AuthStatus.unauthenticated,
  );
}
