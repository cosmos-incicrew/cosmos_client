// 로그인 상태 전이 검증.
//
// 여기서 잡는 것은 전부 "로그를 안 보면 원인을 모르는" 부류다.
//  - 토큰 갱신 한 번에 온보딩을 마친 사용자가 온보딩으로 되돌아가는 것
//  - 프로필 응답 타입이 어긋나면 상태가 unknown 에 멈춰 라우터가 죽는 것
//  - 게스트 상태가 세션 없음 이벤트에 지워지는 것
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:cosmos_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmos_app/features/onboarding/data/profile_repository.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// 프로필 GET 응답을 원하는 대로 돌려주는 대역.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status, this.body, {this.delay = Duration.zero});

  final int status;
  final Object body;

  /// 프로필 조회가 느린 상황 — 그 사이 다른 인증 이벤트가 끼어들 수 있다.
  final Duration delay;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 세션 복원이 "로그인됨"을 돌려주는 대역.
///
/// 테스트에는 dart-define 이 없어 Env.hasSupabase 가 false 다. 진짜
/// AuthRepository 를 쓰면 restoreSession() 이 즉시 미인증을 반환해
/// _apply 의 인증 분기(프로필 조회·onboarded 병합)에 영영 도달하지 않는다.
class _SignedInRepository extends AuthRepository {
  const _SignedInRepository();

  @override
  Future<AuthState> restoreSession() async => const AuthState(
        status: AuthStatus.authenticated,
        provider: AuthProvider.google,
        userId: 'uuid',
      );
}

ProviderContainer _container({
  required Stream<sb.AuthState> authChanges,
  int status = 200,
  Object body = const <String, dynamic>{},
  bool signedIn = true,
  Duration profileDelay = Duration.zero,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://test.local'))
    ..httpClientAdapter = _StubAdapter(status, body, delay: profileDelay);
  return ProviderContainer(
    overrides: [
      if (signedIn)
        authRepositoryProvider.overrideWithValue(const _SignedInRepository()),
      authStateStreamProvider.overrideWithValue(authChanges),
      profileRepositoryProvider.overrideWithValue(ProfileRepository(dio)),
    ],
  );
}

const _validProfile = {
  'user_id': 'uuid',
  'nickname': '민경',
  'age': 28,
  'gender': 'female',
  'skin_concerns': ['acne'],
  'is_pregnant': null,
  'is_nursing': null,
  'created_at': null,
  'updated_at': null,
};

/// 세션 복원 → 프로필 조회 → 상태 반영까지가 여러 번의 비동기 왕복이다.
/// Duration.zero 한 번으로는 다 돌지 않는다.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 50));

/// 실제 Supabase 세션 이벤트. _apply 를 두 번째로 돌리려면 이게 필요하다.
sb.AuthState _sessionEvent({String userId = 'uuid'}) => sb.AuthState(
      sb.AuthChangeEvent.tokenRefreshed,
      sb.Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: sb.User(
          id: userId,
          appMetadata: const {'provider': 'google'},
          userMetadata: const {},
          aud: 'authenticated',
          createdAt: '2026-07-22T00:00:00Z',
        ),
      ),
    );

void main() {
  test('세션이 없으면 미인증으로 내려간다', () async {
    final c = _container(
        authChanges: const Stream.empty(), status: 404, signedIn: false);
    addTearDown(c.dispose);

    c.read(authControllerProvider);
    await _settle();

    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('프로필 응답 타입이 어긋나도 상태가 unknown 에 멈추지 않는다', () async {
    // age 가 int 가 아니면 파싱이 TypeError(Error 계열)를 던진다. 이때 상태가
    // unknown 에 남으면 라우터가 아무 데도 보내지 않아 앱이 스플래시에 갇힌다.
    final c = _container(
      authChanges: const Stream.empty(),
      body: {..._validProfile, 'age': 28.5},
    );
    addTearDown(c.dispose);

    c.read(authControllerProvider);
    await _settle();

    expect(c.read(authControllerProvider).status, isNot(AuthStatus.unknown));
  });

  test('조회가 실패하면 온보딩을 마친 사실이 유지된다', () async {
    // 네트워크가 잠깐 끊겨 프로필 GET 이 500 이 나는 것만으로 온보딩으로
    // 되돌아가면, 쓰던 화면에서 갑자기 튕긴다. 모를 때는 로컬 믿음을 지킨다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(authChanges: events.stream, status: 500);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await _settle();
    controller.completeOnboarding();

    events.add(_sessionEvent());
    await _settle();

    expect(c.read(authControllerProvider).onboarded, isTrue);
  });

  test('앱을 켰을 때 서버에 프로필이 없으면 온보딩으로 보낸다', () async {
    // 갓 켠 상태의 onboarded 는 false 라 서버가 정답이 된다. 여기서 홈으로
    // 보내면 서버에 행이 없는 채로 머물고 추천이 영영 409 로 막힌다.
    final c = _container(authChanges: const Stream.empty(), status: 404);
    addTearDown(c.dispose);

    c.read(authControllerProvider);
    await _settle();

    expect(c.read(authControllerProvider).onboarded, isFalse);
  });

  test('프로필이 불완전해도 세션 도중에 온보딩으로 쫓겨나지 않는다', () async {
    // 온보딩 화면이 나이·고민을 강제하지 않아, 빈 폼으로 넘어가면 서버 행은
    // 생기지만 완료 조건(age + concerns)은 못 채운다. 이때 토큰 갱신마다
    // 온보딩으로 되돌리면 쓰던 화면에서 50분 주기로 튕긴다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(
      authChanges: events.stream,
      body: {..._validProfile, 'age': null, 'skin_concerns': <String>[]},
    );
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await _settle();
    controller.completeOnboarding();

    events.add(_sessionEvent());
    await _settle();

    expect(c.read(authControllerProvider).onboarded, isTrue);
  });

  test('프로필 조회 도중 로그아웃되면 낡은 인증 상태로 되살아나지 않는다', () async {
    // 조회가 느린 사이 세션이 끊기면(갱신 실패 → 인터셉터 signOut) 미인증이
    // 먼저 반영된다. 뒤늦게 끝난 조회가 authenticated 로 덮으면, 라우터는
    // isSignedIn && !onboarded 로 보고 프로필 화면에 가둔다 — 로그인 시트로
    // 돌아갈 길이 없어 앱을 껐다 켜야 한다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(
      authChanges: events.stream,
      status: 404,
      profileDelay: const Duration(milliseconds: 60),
    );
    addTearDown(c.dispose);

    c.read(authControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // 조회가 아직 진행 중일 때 로그아웃이 들어온다.
    events.add(const sb.AuthState(sb.AuthChangeEvent.signedOut, null));
    await _settle();
    await _settle();

    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('로그아웃 이벤트가 프로필을 비운다', () async {
    // signOut() 만 clear() 를 부르면, 401 인터셉터의 갱신 실패처럼 그 함수를
    // 거치지 않는 로그아웃 경로에서 이전 사용자의 프로필이 그대로 남는다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(authChanges: events.stream, body: _validProfile);
    addTearDown(c.dispose);

    c.read(authControllerProvider);
    await _settle();
    expect(c.read(userProfileProvider).nickname, '민경');

    events.add(const sb.AuthState(sb.AuthChangeEvent.signedOut, null));
    await _settle();

    expect(c.read(userProfileProvider).nickname, isNull);
  });

  test('다른 사용자가 로그인하면 앞사람의 온보딩 완료를 물려받지 않는다', () async {
    // 조회가 실패한 채 신원이 바뀌면, 로컬 믿음이 뒷사람에게 넘어가 앞사람의
    // 온보딩 완료로 홈에 들어간다 — 정작 자기 프로필은 서버에 없다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(authChanges: events.stream, status: 500);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await _settle();
    controller.completeOnboarding();
    expect(c.read(authControllerProvider).onboarded, isTrue);

    events.add(_sessionEvent(userId: 'other-uuid'));
    await _settle();

    expect(c.read(authControllerProvider).userId, 'other-uuid');
    expect(c.read(authControllerProvider).onboarded, isFalse);
  });

  test('게스트가 실계정으로 로그인하면 게스트의 온보딩 완료를 물려받지 않는다', () async {
    // 게스트는 onboarded: true 로 시작한다(서버를 안 쓰니 막을 이유가 없다).
    // 그 값이 실계정으로 넘어가면, 서버에 자기 프로필이 없는데도 홈에 들어가
    // 추천이 영영 409 로 막힌다. 게스트의 userId 는 'guest' 라 실계정 uuid 와
    // 절대 같지 않으므로 sameIdentity 가 이를 끊는다.
    final events = StreamController<sb.AuthState>.broadcast();
    addTearDown(events.close);
    final c = _container(authChanges: events.stream, status: 404, signedIn: false);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await controller.signInAsGuest();
    expect(c.read(authControllerProvider).onboarded, isTrue);

    events.add(_sessionEvent());
    await _settle();

    expect(c.read(authControllerProvider).status, AuthStatus.authenticated);
    expect(c.read(authControllerProvider).onboarded, isFalse);
  });

  test('게스트는 서버 세션 없이도 로그인 상태로 남는다', () async {
    final c = _container(authChanges: const Stream.empty(), status: 404);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await controller.signInAsGuest();

    final state = c.read(authControllerProvider);
    expect(state.status, AuthStatus.guest);
    expect(state.isSignedIn, isTrue);
  });

  test('탈퇴에 성공하면 로그아웃까지 이어진다', () async {
    final c = _container(authChanges: const Stream.empty(), status: 204);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await controller.signInAsGuest();
    await controller.deleteAccount();

    expect(c.read(authControllerProvider).status, AuthStatus.unauthenticated);
  });

  test('탈퇴에 실패하면 로그아웃하지 않는다', () async {
    // 탈퇴된 줄 알았는데 계정이 그대로 남아 있는 상태가 제일 나쁘다.
    // 실패는 그대로 올려 화면이 안내하게 하고, 세션은 건드리지 않는다.
    final c = _container(authChanges: const Stream.empty(), status: 500);
    addTearDown(c.dispose);

    final controller = c.read(authControllerProvider.notifier);
    await controller.signInAsGuest();

    await expectLater(controller.deleteAccount(), throwsA(isA<DioException>()));
    expect(c.read(authControllerProvider).status, isNot(AuthStatus.unauthenticated));
  });
}
