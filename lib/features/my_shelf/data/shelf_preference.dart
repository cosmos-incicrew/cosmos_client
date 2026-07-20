import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 선호 / 기피 구분.
enum PreferenceKind {
  like('선호'),
  dislike('기피');

  const PreferenceKind(this.label);

  /// 화면에 그대로 쓰는 한글 라벨.
  final String label;
}

/// 화장대에 담긴 항목 하나 (제품 또는 성분).
class ShelfEntry {
  const ShelfEntry({
    required this.id,
    required this.name,
    required this.isProduct,
    required this.kind,
  });

  final int id;
  final String name;

  /// true = 제품, false = 성분.
  final bool isProduct;
  final PreferenceKind kind;

  /// 제품 3번과 성분 3번이 겹치지 않도록 종류까지 묶어 키를 만든다.
  String get key => '${isProduct ? 'p' : 'i'}$id';

  @override
  bool operator ==(Object other) =>
      other is ShelfEntry && other.key == key && other.kind == kind;

  @override
  int get hashCode => Object.hash(key, kind);
}

/// 내 화장대 — 선호·기피 목록.
///
/// ⚠️ 지금은 메모리에만 저장한다 (앱 끄면 사라짐).
/// 백엔드가 붙으면 이 Notifier 안을 API 호출로 바꾸면 된다.
class ShelfPreferenceNotifier extends StateNotifier<List<ShelfEntry>> {
  ShelfPreferenceNotifier() : super(const []);

  /// 담기. 같은 항목이 이미 있으면 선호↔기피만 갱신한다.
  void add(ShelfEntry entry) {
    final rest = state.where((e) => e.key != entry.key).toList();
    state = [...rest, entry];
  }

  void remove(ShelfEntry entry) {
    state = state.where((e) => e.key != entry.key).toList();
  }

  /// 이미 담긴 항목이면 그 구분을, 아니면 null.
  PreferenceKind? kindOf({required int id, required bool isProduct}) {
    final key = '${isProduct ? 'p' : 'i'}$id';
    for (final e in state) {
      if (e.key == key) return e.kind;
    }
    return null;
  }

  List<ShelfEntry> byKind(PreferenceKind kind) =>
      state.where((e) => e.kind == kind).toList();
}

final shelfPreferenceProvider =
    StateNotifierProvider<ShelfPreferenceNotifier, List<ShelfEntry>>(
  (ref) => ShelfPreferenceNotifier(),
);
