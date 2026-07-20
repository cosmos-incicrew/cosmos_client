import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'skin_concern.dart';

/// 온보딩에서 받은 내 프로필.
///
/// 추천·보고서가 이 값을 읽어 "내 고민"을 반영한다.
class UserProfile {
  const UserProfile({
    this.nickname,
    this.age,
    this.gender,
    this.pregnancy = false,
    this.concerns = const {},
  });

  final String? nickname;
  final int? age;

  /// '여성' / '남성'. 안 고르면 null.
  final String? gender;

  /// 임신·수유 중 (여성만 해당).
  final bool pregnancy;

  /// 선택한 피부고민 (다중).
  final Set<SkinConcern> concerns;

  /// 추천에 쓸 만한 정보가 하나라도 있나.
  bool get hasConcerns => concerns.isNotEmpty;

  UserProfile copyWith({
    String? nickname,
    int? age,
    String? gender,
    bool? pregnancy,
    Set<SkinConcern>? concerns,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      pregnancy: pregnancy ?? this.pregnancy,
      concerns: concerns ?? this.concerns,
    );
  }
}

/// 내 프로필 — 온보딩에서 저장하고 추천·보고서가 읽는다.
///
/// ⚠️ 지금은 메모리에만 저장한다 (앱 끄면 사라짐 — 화장대·BSTI와 같은 방식).
/// 백엔드가 붙으면 이 Notifier 안을 API 호출로 바꾸면 된다.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  UserProfileNotifier() : super(const UserProfile());

  /// 온보딩 프로필 저장.
  void save({
    String? nickname,
    int? age,
    String? gender,
    bool pregnancy = false,
    Set<SkinConcern> concerns = const {},
  }) {
    state = UserProfile(
      nickname: nickname,
      age: age,
      gender: gender,
      pregnancy: pregnancy,
      concerns: concerns,
    );
  }

  /// 로그아웃 등으로 비우기.
  void clear() => state = const UserProfile();
}

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier();
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
