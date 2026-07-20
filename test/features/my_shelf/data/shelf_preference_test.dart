// 선호/기피 저장소 검증.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('선호로 담으면 목록에 들어간다', () {
    final n = ShelfPreferenceNotifier();
    n.add(const ShelfEntry(
        id: 1, name: '토너', isProduct: true, kind: PreferenceKind.like));

    expect(n.kindOf(id: 1, isProduct: true), PreferenceKind.like);
    expect(n.byKind(PreferenceKind.like).length, 1);
    expect(n.byKind(PreferenceKind.dislike), isEmpty);
  });

  test('같은 항목을 다시 담으면 선호↔기피가 갱신된다 (중복 안 쌓임)', () {
    final n = ShelfPreferenceNotifier();
    const e = ShelfEntry(
        id: 1, name: '토너', isProduct: true, kind: PreferenceKind.like);
    n.add(e);
    n.add(const ShelfEntry(
        id: 1, name: '토너', isProduct: true, kind: PreferenceKind.dislike));

    // 선호에서 빠지고 기피에만 있어야 한다 (둘 다 있으면 중복)
    expect(n.byKind(PreferenceKind.like), isEmpty);
    expect(n.byKind(PreferenceKind.dislike).length, 1);
    expect(n.kindOf(id: 1, isProduct: true), PreferenceKind.dislike);
  });

  test('제품 1번과 성분 1번은 서로 다른 항목이다', () {
    final n = ShelfPreferenceNotifier();
    n.add(const ShelfEntry(
        id: 1, name: '토너', isProduct: true, kind: PreferenceKind.like));
    n.add(const ShelfEntry(
        id: 1, name: '글리세린', isProduct: false, kind: PreferenceKind.dislike));

    // id 가 같아도 종류가 다르면 각각 담긴다.
    expect(n.byKind(PreferenceKind.like).length, 1);
    expect(n.byKind(PreferenceKind.dislike).length, 1);
    expect(n.kindOf(id: 1, isProduct: true), PreferenceKind.like);
    expect(n.kindOf(id: 1, isProduct: false), PreferenceKind.dislike);
  });

  test('안 담은 항목은 null', () {
    final n = ShelfPreferenceNotifier();
    expect(n.kindOf(id: 99, isProduct: true), isNull);
  });

  test('빼면 목록에서 사라진다', () {
    final n = ShelfPreferenceNotifier();
    const e = ShelfEntry(
        id: 1, name: '토너', isProduct: true, kind: PreferenceKind.like);
    n.add(e);
    n.remove(e);

    expect(n.byKind(PreferenceKind.like), isEmpty);
    expect(n.kindOf(id: 1, isProduct: true), isNull);
  });
}
