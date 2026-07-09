/// 앱 전역 인증 상태 모델.
enum AuthStatus { unknown, unauthenticated, guest, authenticated }

/// 로그인 방식.
enum AuthProvider { none, guest, kakao, naver, google, apple }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.provider = AuthProvider.none,
    this.userId,
    this.displayName,
  });

  final AuthStatus status;
  final AuthProvider provider;
  final String? userId;
  final String? displayName;

  bool get isSignedIn =>
      status == AuthStatus.authenticated || status == AuthStatus.guest;

  AuthState copyWith({
    AuthStatus? status,
    AuthProvider? provider,
    String? userId,
    String? displayName,
  }) {
    return AuthState(
      status: status ?? this.status,
      provider: provider ?? this.provider,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
    );
  }

  static const unauthenticated = AuthState(
    status: AuthStatus.unauthenticated,
  );
}
