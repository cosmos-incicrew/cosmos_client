// 성분 해설 API(①②③) 응답 파싱 검증.
//
// 노션 "성분 해설 API 명세"의 예시 JSON 을 **그대로** 넣고 파싱한다.
// safety 3형태 분류와 "주의:" 줄 분리도 명세 규칙대로인지 본다.
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/ingredient/data/models/ingredient_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('① 개별 해설 — 명세 예시가 그대로 파싱된다', () {
    final d = IngredientDetail.fromJson(const {
      'status': 'ok',
      'ingredient_id': 2700,
      'name': '나이아신아마이드',
      'body': '나이아신아마이드는 비타민 B3 계열 성분으로, 피부 톤을 밝게 하고 결을 매끄럽게 하는 데 도움을 줍니다.',
      'safety': '[공식 규제] 사용 한도 / 0.5% 이하 자극이 적은 편입니다.',
      'reference_source': 'PubChem',
      'source_verified': true,
      'reason': null,
    });

    expect(d.status, InsightStatus.ok);
    expect(d.name, '나이아신아마이드');
    expect(d.safetyKind, SafetyKind.official); // "[공식 규제]" → 경고색 강조
    expect(d.sourceVerified, isTrue);
  });

  test('safety 세 형태가 명세대로 분류된다', () {
    // 공식 규제 → 강조.
    expect(classifySafety('[공식 규제] 사용 한도'), SafetyKind.official);
    // 일반 참고 → 보통 표시.
    expect(classifySafety('자극이 적은 편입니다'), SafetyKind.general);
    // "확인 불가" = 모른다는 뜻. 절대 "안전"으로 분류되면 안 된다.
    expect(classifySafety('안전성 확인 불가'), SafetyKind.unknown);
    expect(classifySafety(null), SafetyKind.unknown);
  });

  test('② 제품 요약 — 명세 예시가 그대로 파싱된다', () {
    final s = ProductSummary.fromJson(const {
      'status': 'ok',
      'top_ingredients': [
        {'ingredient_id': 2700, 'name': '나이아신아마이드'},
        {'ingredient_id': 2247, 'name': '히알루론산'},
        {'ingredient_id': 3851, 'name': '판테놀'},
      ],
      'summary':
          '이 제품은 건성·수분 부족 피부에 적합하며, 보습과 진정에 도움을 주는 성분들로 구성되어 있습니다.\n주의: 사용 한도 규제가 있는 성분(○○)이 포함되어 있습니다.',
      'source_verified': true,
      'reason': null,
    });

    expect(s.status, InsightStatus.ok);
    expect(s.topIngredients, hasLength(3));
    expect(s.topIngredients.first.name, '나이아신아마이드');

    // "주의:" 줄이 분리돼 강조 표시로 이어진다 (명세 §7).
    final split = splitCaution(s.summary!);
    expect(split.body, contains('건성·수분 부족'));
    expect(split.body, isNot(contains('주의:')));
    expect(split.caution, startsWith('주의:'));
  });

  test('주의 줄이 없으면 caution 은 null (명세: 없으면 생략)', () {
    final split = splitCaution('보습 성분 위주의 무난한 구성입니다.');
    expect(split.caution, isNull);
    expect(split.body, '보습 성분 위주의 무난한 구성입니다.');
  });

  test('③ 비교 해설 — 명세 예시가 그대로 파싱된다', () {
    final c = ComparisonSummary.fromJson(const {
      'status': 'ok',
      'summary':
          '두 제품 모두 정제수를 기본으로 하며 보습 성분을 포함하고 있습니다. 제품 A에는 글리세린이 추가로 들어 있어 수분 유지에 관여합니다.\n주의: 글리세린은 배합 한도 규제가 있는 성분입니다.',
      'source_verified': true,
      'reason': null,
    });

    expect(c.status, InsightStatus.ok);
    expect(splitCaution(c.summary!).caution, contains('글리세린'));
  });

  test('"확인 불가"는 에러가 아니다 — reason 과 함께 정상 파싱', () {
    final d = IngredientDetail.fromJson(const {
      'status': '확인 불가',
      'ingredient_id': 999,
      'name': '어떤성분', // 명세: name 은 정상적으로 채워져 옴
      'body': null,
      'safety': null,
      'source_verified': true,
      'reason': '해설할 근거 문서가 아직 없습니다',
    });

    expect(d.status, InsightStatus.unavailable);
    expect(d.name, '어떤성분');
    expect(d.reason, isNotNull);
  });

  test('source_verified=false 여도 본문은 유효하다 (출처만 숨김)', () {
    final d = IngredientDetail.fromJson(const {
      'status': 'ok',
      'ingredient_id': 1,
      'name': '성분',
      'body': '본문은 정상.',
      'source_verified': false,
    });
    // 파싱이 본문을 버리면 안 된다 — 출처 표시 여부만 화면이 결정한다.
    expect(d.body, '본문은 정상.');
    expect(d.sourceVerified, isFalse);
  });
}
