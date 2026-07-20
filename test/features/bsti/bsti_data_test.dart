// BSTI 데이터·엔진 무결성 검증.
// 원본 Supabase 시드(20260714121000_create_bsti_tables.sql)와 개수·규칙이 맞는지 확인.
//
// 이 테스트는 소스와 같은 폴더(lib/features/bsti/)에 둔다. flutter_test는 dev 의존성이라
// lib에서 참조하면 depend_on_referenced_packages 경고가 나므로 이 파일에서만 무시한다.
// 실행: flutter test lib/features/bsti/
// ignore_for_file: depend_on_referenced_packages
import 'package:cosmos_app/features/bsti/bsti.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('데이터 개수 (원본 SQL 시드 기준)', () {
    test('성분 34개', () => expect(kBstiIngredients.length, 34));
    test('자차 6개', () => expect(kBstiSunscreens.length, 6));
    test('근거 15개', () => expect(kBstiReferences.length, 15));
    test('축 4개', () => expect(kBstiAxes.length, 4));
    test('문항 20개', () => expect(kBstiQuestions.length, 20));
    test('유형 16개', () => expect(kBstiSkinTypes.length, 16));

    test('보기 총 80개 (문항당 4개)', () {
      final total = kBstiQuestions.fold<int>(0, (n, q) => n + q.options.length);
      expect(total, 80);
      for (final q in kBstiQuestions) {
        expect(q.options.length, 4, reason: 'Q${q.id} 보기 수');
      }
    });

    test('유형↔성분 매핑 총 216개', () {
      final total = kBstiSkinTypes.values
          .fold<int>(0, (n, t) => n + t.recommend.length + t.avoid.length);
      expect(total, 216);
    });
  });

  group('참조 무결성', () {
    test('모든 유형의 성분 id가 사전에 존재', () {
      for (final t in kBstiSkinTypes.values) {
        for (final link in [...t.recommend, ...t.avoid]) {
          expect(kBstiIngredients.containsKey(link.ingredientId), isTrue,
              reason: '${t.code} → ${link.ingredientId} 없음');
        }
      }
    });

    test('모든 유형의 자차 id가 존재', () {
      for (final t in kBstiSkinTypes.values) {
        expect(kBstiSunscreens.containsKey(t.sunscreenId), isTrue,
            reason: '${t.code} → ${t.sunscreenId}');
      }
    });

    test('성분·자차의 ref_code가 근거에 존재', () {
      for (final ing in kBstiIngredients.values) {
        for (final r in ing.refCodes) {
          expect(kBstiReferences.containsKey(r), isTrue,
              reason: '${ing.id} → $r');
        }
      }
      for (final ss in kBstiSunscreens.values) {
        for (final r in ss.refCodes) {
          expect(kBstiReferences.containsKey(r), isTrue,
              reason: '${ss.id} → $r');
        }
      }
    });

    test('유형 코드가 4축 극과 일치', () {
      for (final t in kBstiSkinTypes.values) {
        expect('${t.oil}${t.sensitivity}${t.pigment}${t.aging}', t.code);
      }
    });

    test('이미지 경로가 코드 기반으로 cat/label 두 벌 생성', () {
      for (final t in kBstiSkinTypes.values) {
        expect(t.catImageAsset, 'assets/images/bsti/cat/${t.code}.png');
        expect(t.labelImageAsset, 'assets/images/bsti/label/${t.code}.png');
      }
    });

    test('cutoff = 2.5 × 문항수, 실제 문항 수와 일치', () {
      for (final axis in kBstiAxes) {
        expect(axis.cutoff, axis.questionCount * 2.5);
        final actual =
            kBstiQuestions.where((q) => q.axisCode == axis.code).length;
        expect(actual, axis.questionCount, reason: '${axis.code} 문항 수');
      }
    });
  });

  group('채점 엔진', () {
    // 모든 문항에 같은 score를 답한 경우의 코드.
    String codeForAll(int score) => BstiEngine.computeCode(
        {for (final q in kBstiQuestions) q.id: score});

    test('전부 4점 → 높은 극 OSPW', () {
      expect(codeForAll(4), 'OSPW');
    });

    test('전부 1점 → 낮은 극 DRNT', () {
      expect(codeForAll(1), 'DRNT');
    });

    test('경계값: 정확히 cutoff면 높은 극', () {
      // oil 5문항: score 합 12.5가 되려면 정수로 불가 → 13(>=12.5)=O, 12(<12.5)=D 확인.
      final o = BstiEngine.computeCode({
        1: 3, 2: 3, 3: 3, 4: 2, 5: 2, // oil 합 13 → O
        for (final q in kBstiQuestions.where((q) => q.axisCode != 'oil')) q.id: 1,
      });
      expect(o[0], 'O');
      final d = BstiEngine.computeCode({
        1: 3, 2: 3, 3: 2, 4: 2, 5: 2, // oil 합 12 → D
        for (final q in kBstiQuestions.where((q) => q.axisCode != 'oil')) q.id: 1,
      });
      expect(d[0], 'D');
    });

    test('16개 유형 전부 도달 가능 + diagnose 성공', () {
      // computeCode가 내는 코드는 항상 kBstiSkinTypes에 존재해야 한다.
      // 모든 축 극 조합(2^4=16)을 강제로 만들어 확인.
      for (var mask = 0; mask < 16; mask++) {
        final answers = <int, int>{};
        for (var a = 0; a < kBstiAxes.length; a++) {
          final high = (mask >> a) & 1 == 1;
          for (final q
              in kBstiQuestions.where((q) => q.axisCode == kBstiAxes[a].code)) {
            answers[q.id] = high ? 4 : 1;
          }
        }
        final diag = BstiEngine.diagnose(answers);
        expect(kBstiSkinTypes.containsKey(diag.code), isTrue);
        expect(diag.recommendedIngredients, isNotEmpty);
      }
    });

    test('legacy 변환: 권장/기피 성분 이름·축 채워짐', () {
      final diag =
          BstiEngine.diagnose({for (final q in kBstiQuestions) q.id: 4});
      final legacy = diag.toLegacyResult();
      expect(legacy.typeCode, 'OSPW');
      expect(legacy.axes.length, 4);
      expect(legacy.recommendedIngredients, contains('나이아신아마이드'));
      expect(legacy.cautionIngredients, isNotEmpty);
    });
  });
}
