import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'profile_repository.dart';
import 'skin_concern.dart';

/// 임신·수유 선택값. 화면·서버 전송이 공유하는 단일 소스.
/// (안 물어본 상태는 null — "해당없음"과 구분해야 금기 검사가 정확해진다)
const String kPregnancyNone = 'none';
const String kPregnancyPregnant = 'pregnant';
const String kPregnancyNursing = 'nursing';

/// 온보딩에서 받은 내 프로필.
///
/// 추천·보고서가 이 값을 읽어 "내 고민"을 반영한다.
class UserProfile {
  const UserProfile({
    this.nickname,
    this.age,
    this.gender,
    this.pregnancy,
    this.concerns = const {},
    this.bstiType,
  });

  final String? nickname;
  final int? age;

  /// 'female' / 'male'. 안 고르면 null. (화면 라벨만 한글이고 값은 코드)
  final String? gender;

  /// 임신·수유 여부 — [kPregnancyNone] · [kPregnancyPregnant] ·
  /// [kPregnancyNursing] 중 하나. 여성 선택 시에만 묻고, 안 물었으면 null.
  final String? pregnancy;

  /// 선택한 피부고민 (다중).
  final Set<SkinConcern> concerns;

  /// BSTI 16타입 코드 (예: 'OSPW'). 검사 전이면 null.
  /// 검사 결과의 단일 소스다 — 별도 저장소를 두면 프로필 재조회 때 어긋난다.
  final String? bstiType;

  /// 추천에 쓸 만한 정보가 하나라도 있나.
  bool get hasConcerns => concerns.isNotEmpty;

  /// 서버 추천 게이트와 같은 기준 (cosmos_server `s1_context.build_context`).
  bool get isOnboardingComplete => age != null && concerns.isNotEmpty;

  UserProfile copyWith({
    String? nickname,
    int? age,
    String? gender,
    String? pregnancy,
    Set<SkinConcern>? concerns,
    String? bstiType,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      pregnancy: pregnancy ?? this.pregnancy,
      concerns: concerns ?? this.concerns,
      bstiType: bstiType ?? this.bstiType,
    );
  }
}

/// 내 프로필 — 온보딩에서 저장하고 추천·보고서가 읽는다.
///
/// 화면 상태를 먼저 갱신하고 서버에 올린다. 서버 저장이 실패해도(게스트·오프라인)
/// 로컬 추천은 계속 되게 하려는 것이다 — 대신 실패는 로그로 남긴다.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier(this._repository) : super(const UserProfile());

  final ProfileRepository _repository;

  /// 서버 프로필을 한 번이라도 확인했는지. 404(프로필 없음)를 받은 것도 확인이다.
  ///
  /// 서버 저장은 **전체 덮어쓰기**다. 조회가 실패해 비어 있을 뿐인 state 를 올리면
  /// 멀쩡한 프로필이 지워진다 — 조회 실패 후 라우터가 온보딩으로 보내면 폼이
  /// 백지로 열리고, HOME 한 번에 전 항목이 null 로 저장되는 경로가 실재했다.
  /// 읽지 않은 것은 쓰지 않는다.
  bool _serverStateKnown = false;

  /// 프로필 저장. 전체 덮어쓰기이므로 **완성된 [UserProfile] 을 통째로** 받는다.
  ///
  /// 항목별 named 인자로 받으면 `save(concerns: ...)` 같은 호출이 자연스러워 보이는데,
  /// 생략한 항목이 로컬·서버 양쪽에서 null 이 된다.
  Future<void> save(UserProfile profile) async {
    // BSTI 는 검사 화면에서만 들어온다. 넘어온 값이 없으면 현재 값을 지킨다 —
    // 호출자마다 챙기게 하면 언젠가 한 곳이 빠뜨려 검사 결과가 사라진다.
    state = profile.bstiType == null
        ? profile.copyWith(bstiType: state.bstiType)
        : profile;
    await _push();
  }

  /// BSTI 검사 완료 — 타입만 바꾸고 프로필 **전체**를 다시 올린다.
  /// 타입만 보내면 서버의 전체 덮어쓰기에 닉네임·나이·고민이 날아간다.
  Future<void> saveBstiType(String typeCode) async {
    state = state.copyWith(bstiType: typeCode);
    await _push();
  }

  /// 현재 상태를 서버에 올린다. 실패해도 로컬 상태는 유지한다.
  Future<void> _push() async {
    if (!_serverStateKnown) {
      developer.log('서버 프로필을 아직 못 읽었다 — 덮어쓰지 않고 로컬 상태만 유지',
          name: 'profile');
      return;
    }
    try {
      await _repository.save(state);
    } on DioException catch (error, stackTrace) {
      // 게스트는 토큰이 없어 401 이 정상 경로다. 그 밖의 실패도 화면을 막지 않는다.
      developer.log('프로필 서버 저장 실패 — 로컬 상태만 유지',
          name: 'profile', error: error, stackTrace: stackTrace);
    }
  }

  /// 서버 프로필을 불러온다. 반환값은 **온보딩 완료 여부**.
  ///
  /// 행 존재만으로 완료로 보면, 중간 이탈로 생긴 빈 행 때문에 앱은 홈으로 보내는데
  /// 서버 추천은 409 로 막는 상태에 갇힌다.
  Future<bool> load() async {
    final saved = await _repository.fetch();
    // 실패는 예외로 나간다 — 여기 도달했다면 서버 내용을 안다 (없음도 앎이다).
    _serverStateKnown = true;
    if (saved == null) return false;
    // 방금 저장한 BSTI 가 아직 서버에 안 닿았을 수 있다. 맹목적으로 교체하면
    // 결과 화면이 빈 채로 보인다 — 서버가 null 일 때만 로컬 값을 지킨다.
    state = saved.bstiType == null && state.bstiType != null
        ? saved.copyWith(bstiType: state.bstiType)
        : saved;
    return saved.isOnboardingComplete;
  }

  /// 로그아웃 등으로 비우기. 다음 사용자의 프로필은 다시 읽어야 안다.
  void clear() {
    state = const UserProfile();
    _serverStateKnown = false;
  }
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref.watch(profileRepositoryProvider));
});

/// 피부고민 → BSTI 성분 id.
///
/// 고민에 맞는 성분을 추천 근거로 쓴다. BSTI 데이터셋(bsti_dataset.dart)의
/// 실제 id만 쓴다 — 없는 id를 지어내면 추천이 조용히 비어버린다.
const kConcernIngredients = <SkinConcern, List<String>>{
  SkinConcern.pores: ['niac', 'sal'],
  SkinConcern.brightening: ['niac', 'vcd', 'txa', 'arb'],
  SkinConcern.wrinkles: ['retal', 'pept', 'toco'],
  SkinConcern.acne: ['sal', 'aze', 'niac'],
  SkinConcern.redness: ['cica', 'bisa', 'allan'],
  SkinConcern.dryness: ['cera', 'ha', 'gly', 'squa'],
  SkinConcern.sensitivity: ['cica', 'panth', 'allan', 'bisa'],
  SkinConcern.sagging: ['pept', 'retal'],
};
