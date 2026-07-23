// 프로필 저장 + 고민→성분 매핑 검증.
//
// 온보딩에서 고른 피부고민이 실제로 저장되고, 추천이 쓸 수 있는
// BSTI 성분 id로 이어지는지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/onboarding/data/profile_repository.dart';
import 'package:cosmos_app/features/onboarding/data/profile_store.dart';
import 'package:cosmos_app/features/onboarding/data/skin_concern.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('처음엔 비어 있다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    final p = c.read(userProfileProvider);
    expect(p.concerns, isEmpty);
    expect(p.hasConcerns, isFalse);
  });

  test('고른 피부고민이 저장된다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(userProfileProvider.notifier).save(const UserProfile(
      nickname: '테스트',
      age: 28,
      gender: 'female',
      concerns: {SkinConcern.acne, SkinConcern.pores},
    ));

    final p = c.read(userProfileProvider);
    expect(p.nickname, '테스트');
    expect(p.age, 28);
    expect(p.hasConcerns, isTrue);
    expect(p.concerns, containsAll([SkinConcern.acne, SkinConcern.pores]));
  });

  test('빈 프로필은 온보딩 완료가 아니다', () {
    // 온보딩을 중간에 이탈하면 나이·고민이 빈 행이 서버에 남는다. 그걸 완료로 보면
    // 앱은 홈으로 보내는데 서버 추천은 409 로 막아, 빠져나올 수 없는 상태가 된다.
    // 판정 기준은 서버 게이트(s1_context: 나이 + 피부고민)와 같아야 한다.
    expect(const UserProfile().isOnboardingComplete, isFalse);
    expect(const UserProfile(nickname: '민경').isOnboardingComplete, isFalse);
    expect(const UserProfile(age: 28).isOnboardingComplete, isFalse);
    expect(
      const UserProfile(concerns: {SkinConcern.acne}).isOnboardingComplete,
      isFalse,
    );
  });

  test('나이와 고민이 모두 있어야 온보딩 완료다', () {
    const profile = UserProfile(age: 28, concerns: {SkinConcern.acne});
    expect(profile.isOnboardingComplete, isTrue);
  });

  test('고민 8개 전부 BSTI 성분과 연결돼 있다', () {
    // 매핑이 비면 추천이 조용히 아무것도 반영 못 한다.
    for (final concern in SkinConcern.values) {
      final ids = kConcernIngredients[concern];
      expect(ids, isNotNull, reason: '${concern.label} 매핑 없음');
      expect(ids, isNotEmpty, reason: '${concern.label} 매핑 비어 있음');
    }
  });

  test('매핑된 성분 id가 전부 실제 BSTI 데이터에 있다', () {
    // 지어낸 id를 쓰면 추천이 조용히 비어버린다 — 그걸 막는다.
    for (final entry in kConcernIngredients.entries) {
      for (final id in entry.value) {
        expect(kBstiIngredients.containsKey(id), isTrue,
            reason: '${entry.key.label} → 없는 성분 id "$id"');
      }
    }
  });

  test('clear 하면 비워진다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(userProfileProvider.notifier)
        .save(const UserProfile(concerns: {SkinConcern.acne}));
    c.read(userProfileProvider.notifier).clear();
    expect(c.read(userProfileProvider).concerns, isEmpty);
  });

  test('서버 프로필을 못 읽었으면 덮어쓰지 않는다', () async {
    // 조회가 실패하면 state 는 "비었다"가 아니라 "모른다"이다. 그대로 올리면
    // 서버의 전체 덮어쓰기에 멀쩡한 프로필이 지워진다.
    final repo = _RecordingProfileRepository(fetchThrows: true);
    final c = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    await expectLater(
      c.read(userProfileProvider.notifier).load(),
      throwsA(isA<Exception>()),
    );
    await c.read(userProfileProvider.notifier)
        .save(const UserProfile(nickname: '민경', age: 28));

    expect(repo.saved, isEmpty, reason: '읽지 않은 것은 쓰지 않는다');
    // 로컬 상태는 살아 있어야 화면이 입력한 값을 보여준다.
    expect(c.read(userProfileProvider).nickname, '민경');
  });

  test('프로필이 없다는 것을 확인했으면(404) 저장한다', () async {
    // 신규 사용자의 첫 온보딩 저장까지 막으면 안 된다.
    final repo = _RecordingProfileRepository();
    final c = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    expect(await c.read(userProfileProvider.notifier).load(), isFalse);
    await c.read(userProfileProvider.notifier)
        .save(const UserProfile(nickname: '민경', age: 28));

    expect(repo.saved.single.nickname, '민경');
  });

  test('서버가 BSTI 를 아직 모르면 로컬 값을 지킨다', () async {
    // 검사 직후 POST 왕복 중에 토큰 갱신이 오면 load 가 끼어든다.
    // 맹목적으로 교체하면 결과 화면이 빈 채로 보인다.
    final repo = _RecordingProfileRepository(
      profile: const UserProfile(nickname: '민경', age: 28),
    );
    final c = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);

    await c.read(userProfileProvider.notifier).load();
    await c.read(userProfileProvider.notifier).saveBstiType('OSPW');
    await c.read(userProfileProvider.notifier).load();

    expect(c.read(userProfileProvider).bstiType, 'OSPW');
  });
}

/// 저장 호출을 기록하는 대역. fetch 는 지정한 프로필(기본 null=404)을 돌려준다.
class _RecordingProfileRepository implements ProfileRepository {
  _RecordingProfileRepository({this.profile, this.fetchThrows = false});

  final UserProfile? profile;
  final bool fetchThrows;
  final List<UserProfile> saved = [];

  @override
  Future<UserProfile?> fetch() async {
    if (fetchThrows) throw Exception('서버 오류');
    return profile;
  }

  @override
  Future<void> save(UserProfile p) async => saved.add(p);

  @override
  Future<void> deleteAccount() async {}
}
