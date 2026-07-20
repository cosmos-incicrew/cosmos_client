// 시연 사이클 통합 검증.
//
// 로그인(목) → BSTI 검사 → 화장대 담기 → 보고서까지 데이터가 실제로 이어지는지.
// 화면 하나씩이 아니라 "끝까지 도는지"를 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/auth/data/auth_repository.dart';
import 'package:cosmos_app/features/auth/data/auth_state.dart';
import 'package:cosmos_app/features/bsti/bsti_result_store.dart';
import 'package:cosmos_app/features/my_shelf/data/shelf_preference.dart';
import 'package:cosmos_app/features/report/data/report_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('로그인 → BSTI → 화장대 → 보고서가 이어진다', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    // 1. 목 카카오 로그인 — 무조건 성공해야 한다.
    const repo = AuthRepository();
    final auth = await repo.signInWithKakao();
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isSignedIn, isTrue);

    // 2. 보고서는 아직 비어 있다 (검사 전).
    var report = c.read(shelfReportProvider);
    expect(report.typeCode, isNull);
    expect(report.totalScore, isNull);

    // 3. BSTI 검사 완료.
    c.read(bstiResultProvider.notifier).save('OSPW');
    report = c.read(shelfReportProvider);
    expect(report.typeCode, 'OSPW');
    expect(report.isEmpty, isTrue); // 아직 담은 제품 없음

    // 4. 화장대에 목데이터 제품을 담는다.
    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 1,
          name: '아토베리어365 하이드로 에센스',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    // 5. 보고서가 자동으로 다시 계산된다.
    report = c.read(shelfReportProvider);
    expect(report.isEmpty, isFalse);
    expect(report.matches.single.name, '아토베리어365 하이드로 에센스');

    // 6. 목데이터 성분이 BSTI 성분과 실제로 연결돼야 한다.
    //    (연결이 끊기면 근거가 0이라 점수를 못 매긴다)
    final m = report.matches.single;
    expect(m.recommendHits + m.avoidHits, greaterThan(0),
        reason: '제품 성분이 BSTI 권장/주의와 하나도 안 맞으면 보고서가 무의미해진다');
    expect(report.totalScore, isNotNull);
    expect(report.totalScore, inInclusiveRange(0, 100));
  });

  test('재검사하면 보고서 점수가 다시 계산된다', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    c.read(shelfPreferenceProvider.notifier).add(const ShelfEntry(
          id: 1,
          name: '아토베리어365 하이드로 에센스',
          isProduct: true,
          kind: PreferenceKind.like,
        ));

    c.read(bstiResultProvider.notifier).save('OSPW');
    final first = c.read(shelfReportProvider).totalScore;

    // 다른 유형으로 재검사 → 권장/주의 성분이 달라지므로 점수도 달라질 수 있다.
    c.read(bstiResultProvider.notifier).save('DRNT');
    final second = c.read(shelfReportProvider).totalScore;

    // 값이 같을 수도 있지만, 계산 자체는 새 유형 기준으로 다시 돌아야 한다.
    expect(c.read(shelfReportProvider).typeCode, 'DRNT');
    expect(first, isNotNull);
    expect(second, isNotNull);
  });
}
