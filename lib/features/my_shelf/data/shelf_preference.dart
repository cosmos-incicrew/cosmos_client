import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_storage.dart';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'isProduct': isProduct,
        'kind': kind.name,
      };

  factory ShelfEntry.fromJson(Map<String, dynamic> json) => ShelfEntry(
        id: json['id'] as int,
        name: json['name'] as String,
        isProduct: json['isProduct'] as bool,
        kind: PreferenceKind.values.firstWhere(
          (k) => k.name == json['kind'],
          orElse: () => PreferenceKind.like,
        ),
      );
}

/// 내 화장대 — 선호·기피 목록.
///
/// 로컬(Hive)에 자동 저장된다 — 담거나 빼면 즉시 기록되고, 앱을 다시 켜면
/// 그대로 복원된다. (서버 화장대 API 가 생기면 여기서 동기화로 확장)
class ShelfPreferenceNotifier extends StateNotifier<List<ShelfEntry>> {
  ShelfPreferenceNotifier() : super(_restore());

  static const _storageKey = 'shelf_entries';

  /// 저장된 화장대 복원. 저장소가 없거나(테스트) 형식이 깨지면 빈 목록.
  static List<ShelfEntry> _restore() {
    try {
      final raw = LocalStorage.prefs.get(_storageKey) as String?;
      if (raw == null) return const [];
      return [
        for (final item in jsonDecode(raw) as List)
          ShelfEntry.fromJson(item as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// 현재 화장대를 로컬에 기록. (실패해도 화면 동작은 막지 않는다)
  void persist() {
    try {
      LocalStorage.prefs.put(
          _storageKey, jsonEncode([for (final e in state) e.toJson()]));
    } catch (_) {}
  }

  /// 담기. 같은 항목이 이미 있으면 선호↔기피만 갱신한다.
  void add(ShelfEntry entry) {
    final rest = state.where((e) => e.key != entry.key).toList();
    state = [...rest, entry];
    persist();
  }

  void remove(ShelfEntry entry) {
    state = state.where((e) => e.key != entry.key).toList();
    persist();
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
