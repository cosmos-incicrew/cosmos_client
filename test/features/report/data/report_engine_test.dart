// 보고서 점수 계산 검증 — 실제 BSTI 데이터 기준.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/engine/report_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const p1 = ShelfEntry(
      id: 1, name: '테스트크림', isProduct: true, kind: PreferenceKind.like);
  const ing = ShelfEntry(
      id: 1, name: '글리세린', isProduct: false, kind: PreferenceKind.like);

  // 실제 유형 하나를 골라 그 유형의 권장/주의 성분을 그대로 쓴다.
  final type = kBstiSkinTypes.values.first;
  final recId = type.recommend.first.ingredientId;
  final avoId = type.avoid.isNotEmpty ? type.avoid.first.ingredientId : null;

  test('BSTI 검사 전이면 점수를 매기지 않는다', () {
    final r = ReportEngine.build(
      typeCode: null,
      entries: [p1],
      ingredientIdsOf: (_) => [recId],
    );

    expect(r.totalScore, isNull);
    expect(r.matches.single.unknown, isTrue);
    expect(r.summary, contains('BSTI 검사'));
  });

  test('권장성분만 있으면 100점', () {
    final r = ReportEngine.build(
      typeCode: type.code,
      entries: [p1],
      ingredientIdsOf: (_) => [recId],
    );

    expect(r.matches.single.recommendHits, 1);
    expect(r.matches.single.avoidHits, 0);
    expect(r.matches.single.score, 100);
    expect(r.totalScore, 100);
  });

  test('주의성분만 있으면 0점', () {
    if (avoId == null) return; // 주의성분 없는 유형이면 건너뜀
    final r = ReportEngine.build(
      typeCode: type.code,
      entries: [p1],
      ingredientIdsOf: (_) => [avoId],
    );

    expect(r.matches.single.score, 0);
    expect(r.matches.single.verdict, '주의가 필요해요');
  });

  test('성분 정보가 없으면 점수를 지어내지 않는다 (null)', () {
    final r = ReportEngine.build(
      typeCode: type.code,
      entries: [p1],
      ingredientIdsOf: (_) => [],
    );

    expect(r.matches.single.score, isNull);
    expect(r.matches.single.unknown, isTrue);
    expect(r.totalScore, isNull);
  });

  test('성분은 평가 대상이 아니다 (제품만)', () {
    final r = ReportEngine.build(
      typeCode: type.code,
      entries: [ing],
      ingredientIdsOf: (_) => [recId],
    );

    expect(r.matches, isEmpty);
    expect(r.isEmpty, isTrue);
  });

  test('총점은 평가 가능한 제품의 평균', () {
    const p2 = ShelfEntry(
        id: 2, name: '다른제품', isProduct: true, kind: PreferenceKind.like);
    if (avoId == null) return;

    final r = ReportEngine.build(
      typeCode: type.code,
      entries: [p1, p2],
      // 1번은 100점(권장만), 2번은 0점(주의만) → 평균 50
      ingredientIdsOf: (id) => id == 1 ? [recId] : [avoId],
    );

    expect(r.totalScore, 50);
    expect(r.summary, contains('무난'));
  });
}
