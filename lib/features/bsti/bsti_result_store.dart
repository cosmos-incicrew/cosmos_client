import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 내 BSTI 검사 결과 (유형 코드).
///
/// 검사를 마치면 여기 저장되고, 보고서가 이 값을 읽어 제품 적합도를 계산한다.
/// 아직 검사 전이면 null.
///
/// ⚠️ 지금은 메모리에만 저장한다 (앱 끄면 사라짐).
/// 백엔드가 붙으면 저장/복원을 API로 바꾸면 된다.
class BstiResultNotifier extends StateNotifier<String?> {
  BstiResultNotifier() : super(null);

  /// 검사 완료 — 유형 코드 저장 (예: 'OSPW').
  void save(String typeCode) => state = typeCode;

  /// 재검사 시작 등으로 결과를 비운다.
  void clear() => state = null;
}

final bstiResultProvider =
    StateNotifierProvider<BstiResultNotifier, String?>((ref) {
  return BstiResultNotifier();
});
