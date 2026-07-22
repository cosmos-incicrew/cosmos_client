import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding/data/profile_store.dart';

/// 내 BSTI 검사 결과 (유형 코드). 검사 전이면 null.
///
/// 보고서·추천이 이 값을 읽어 제품 적합도를 계산한다.
///
/// [UserProfile.bstiType] 에서 파생된다 — 별도 저장소를 두면 프로필 재조회 때
/// 어긋난다. 저장은 `userProfileProvider.notifier.saveBstiType()`.
final bstiResultProvider = Provider<String?>((ref) {
  return ref.watch(userProfileProvider).bstiType;
});
