import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/network/supabase_client.dart';
import '../../../onboarding/data/profile_repository.dart';
import '../../../onboarding/data/profile_store.dart';
import '../../data/auth_repository.dart';
import '../../data/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const AuthRepository();
});

/// 세션 변화 스트림. 테스트가 가짜 스트림을 끼울 수 있도록 provider 로 뺀다.
final authStateStreamProvider = Provider<Stream<sb.AuthState>>((ref) {
  return SupabaseService.authStateChanges;
});

/// 앱 전역 인증 상태를 관리하는 Notifier.
///
/// 상태의 출처는 두 갈래다.
///  - 로그인 호출의 반환값 (구글은 즉시, 카카오는 딥링크로 돌아온 뒤)
///  - Supabase 세션 스트림 (토큰 갱신·다른 경로 로그아웃)
/// 둘 다 [_apply] 로 모아 온보딩 여부까지 채운 뒤 상태로 만든다.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repo, this._ref, Stream<sb.AuthState> authChanges)
      : super(const AuthState()) {
    _subscription = authChanges.listen(
      (event) => _apply(AuthRepository.stateFromSession(event.session)),
    );
    _restore();
  }

  final AuthRepository _repo;
  final Ref _ref;
  StreamSubscription<sb.AuthState>? _subscription;

  /// 마지막으로 시작한 [_apply] 의 순번. 앱을 켤 때 세션 복원과 스트림의 첫
  /// 이벤트가 둘 다 _apply 를 돌려 프로필 조회가 겹치는데, 늦게 끝난 쪽이
  /// 최신 상태를 덮지 않게 한다.
  int _applySeq = 0;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _restore() async => _apply(await _repo.restoreSession());

  /// 게스트는 Supabase 세션이 없다 — 서버 프로필을 조회하지 않고,
  /// 맞춤 추천 등 서버 API 도 쓰지 못한다.
  Future<void> signInAsGuest() async {
    state = await _repo.signInAsGuest();
  }

  /// 로그인 성공 시 상태는 세션 스트림이 갱신한다 — 여기서 [_apply] 를 또 부르면
  /// 프로필 조회가 두 번 나가고, 늦게 끝난 쪽이 최신 상태를 덮어쓴다.
  Future<void> signInWithGoogle() async {
    await _repo.signInWithGoogle();
  }

  Future<void> signInWithKakao() async {
    await _repo.signInWithKakao();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _ref.read(userProfileProvider.notifier).clear();
    state = AuthState.unauthenticated;
  }

  /// 회원 탈퇴 — 계정을 지우고 로그아웃한다.
  ///
  /// 실패하면 예외를 올린다. 여기서 로그아웃까지 하면 사용자는 탈퇴된 줄 알지만
  /// 계정은 그대로 남는다.
  Future<void> deleteAccount() async {
    await _ref.read(profileRepositoryProvider).deleteAccount();
    await signOut();
  }

  /// 온보딩(프로필·피부고민)을 마쳤을 때 호출 → 홈으로 진입 가능.
  void completeOnboarding() {
    state = state.copyWith(onboarded: true);
  }

  /// 로그인 상태면 서버 프로필을 조회해 온보딩 완료 여부까지 채운다.
  ///
  /// 프로필이 이미 있으면 온보딩을 건너뛴다 — 재설치·재로그인 때마다
  /// 같은 정보를 다시 묻지 않기 위해서다.
  Future<void> _apply(AuthState next) async {
    // 순번은 **모든** 호출에서 올린다. 인증 분기에서만 올리면, 조회가 도는 사이
    // 들어온 로그아웃이 카운터를 안 바꿔 낡은 결과가 그대로 상태를 덮는다.
    final seq = ++_applySeq;

    // 게스트는 Supabase 세션이 없다. 다른 경로의 signedOut 이벤트에 휩쓸려
    // 게스트 상태가 지워지면 쓰던 화면에서 스플래시로 튕긴다.
    // 막을 것은 '로그아웃 방향'뿐이다 — signedIn 까지 버리면 게스트가 실계정으로
    // 승격될 수 없다.
    if (state.status == AuthStatus.guest &&
        next.status == AuthStatus.unauthenticated) {
      return;
    }
    if (next.status != AuthStatus.authenticated) {
      // 로그아웃 경로는 signOut() 만이 아니다 — 401 인터셉터의 갱신 실패,
      // 다른 기기에서의 세션 무효화도 여기로 들어온다. 그 경로들이 프로필을
      // 안 지우면 다음 사람이 로그인했을 때 이전 사용자의 닉네임·나이·고민이
      // 폼에 채워지고, 그대로 저장하면 남의 정보가 내 계정에 들어간다.
      _ref.read(userProfileProvider.notifier).clear();
      state = next;
      return;
    }
    var onboarded = false;
    try {
      onboarded = await _ref.read(userProfileProvider.notifier).load();
    } on Object catch (error, stackTrace) {
      // DioException 만 잡으면 응답 타입이 어긋났을 때 TypeError(Error 계열)가
      // 빠져나가고, state 가 unknown 에 머물러 라우터가 영영 멈춘다.
      developer.log('프로필 조회 실패 — 온보딩 여부는 로컬 상태를 따른다',
          name: 'auth', error: error, stackTrace: stackTrace);
    }
    // await 사이에 더 최신 이벤트가 들어왔으면 이 결과는 이미 낡았다. 그대로 쓰면
    // 조회 도중 세션이 끊긴 사용자가 authenticated 로 되살아나, 라우터가 프로필
    // 화면에 가둔 채 로그인 시트로 돌아갈 길을 막는다.
    if (!mounted || seq != _applySeq) return;
    // 로컬 믿음은 **같은 사람일 때만** 이어받는다. 신원이 바뀌면(게스트 → 실계정,
    // A → B) 앞사람의 온보딩 완료가 뒷사람에게 넘어가, 서버에 자기 행이 없는 채로
    // 홈에 들어가 추천이 영영 409 로 막힌다.
    //
    // 같은 사람 안에서는 유지한다. 앱을 갓 켰을 때 state.onboarded 는 false 라
    // 서버가 정답이 되고, 스티키는 사용자가 이번 세션에 실제로 온보딩을 지난
    // 뒤에만 걸린다 — 나이·고민을 비워둔 사용자가 토큰 갱신마다 쓰던 화면에서
    // 온보딩으로 튕기는 것을 막는다.
    final sameIdentity = next.userId != null && next.userId == state.userId;
    state = next.copyWith(onboarded: onboarded || (sameIdentity && state.onboarded));
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref,
    ref.watch(authStateStreamProvider),
  );
});
