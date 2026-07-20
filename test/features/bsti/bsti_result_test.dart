// BSTI 결과 모델(BstiResult / BstiAxis) 파싱·계산 검증.
// (lib/features/bsti/bsti_result.dart 의 테스트 — 소스와 같은 폴더에 둔다)
// 실행: flutter test lib/features/bsti/
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BstiAxis', () {
    test('축 비율은 왼쪽+오른쪽이 100이다', () {
      const axis = BstiAxis(
        leftCode: 'O',
        leftLabel: '지성',
        leftPercent: 75,
        rightCode: 'D',
        rightLabel: '건성',
      );
      expect(axis.rightPercent, 25);
    });
  });

  group('BstiResult', () {
    test('결과 fromJson 파싱', () {
      final result = BstiResult.fromJson({
        'type_code': 'OSPW',
        'type_name': '진정 먼저 챙기는 풀코스 케어 고양이',
        'axes': [
          {
            'left_code': 'O',
            'left_label': '지성',
            'left_percent': 75,
            'right_code': 'D',
            'right_label': '건성',
          },
        ],
        'recommended_ingredients': ['나이아신아마이드'],
      });
      expect(result.typeCode, 'OSPW');
      expect(result.axes.first.rightPercent, 25);
      expect(result.recommendedIngredients, ['나이아신아마이드']);
    });
  });
}
