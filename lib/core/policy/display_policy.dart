/// 화면 표기 정책 — 기능별로 "무엇을 걸러내고 무엇을 숨길지"를 코드로 명시한다.
///
/// 백엔드 응답은 그대로 받되(API 계약 무변경), **표시 단계에서만** 제한한다.
/// 정책이 늘면 여기에 기능 단위로 추가한다 — 화면 코드에 하드코딩하지 않는다.
library;

/// 제품 상세 — 성분 TOP 목록 정책.
abstract final class ProductIngredientPolicy {
  /// 목록에서 제외할 성분 id — 정제수(물, id 2700)는 거의 모든 제품의
  /// 1번 성분이라 정보 가치가 없다.
  static const Set<int> excludedIds = {2700};

  /// 이름으로도 이중 방어 (id 매핑이 없는 화면 대비).
  static const Set<String> excludedNames = {'정제수'};

  /// 배합순을 유지한 채 제외 성분을 걸러 상위 [count]개를 고른다.
  static List<int> top(List<int> ids, {int count = 10}) =>
      [for (final id in ids) if (!excludedIds.contains(id)) id]
          .take(count)
          .toList();

  /// 제외 후 남는 전체 개수 ("외 N개" 표기용).
  static int remaining(List<int> ids, {int count = 10}) {
    final total = ids.where((id) => !excludedIds.contains(id)).length;
    return total > count ? total - count : 0;
  }
}

/// 성분 해설·제품 요약 — 출처 표기 정책.
///
/// 출처(참고문헌·특허번호 등)는 내부 검증용이라 사용자 화면에서는 숨긴다.
abstract final class SourceDisplayPolicy {
  /// 성분 해설 시트·제품 상세에서 출처 문구를 보여줄지.
  static const bool showSources = false;

  /// 본문 텍스트 안에 섞여 오는 "출처: …" 줄을 떼어낸다.
  /// (LLM 생성문이 말미에 출처 줄을 붙여 보내는 경우가 있다)
  static String stripSourceLines(String text) => text
      .replaceAll(RegExp(r'\n?\s*\(?출처\s*[:：][^\n]*\)?'), '')
      .trimRight();
}

/// 해설 본문을 "역할 / 주의" 소제목 구획으로 나누는 정책.
///
/// ① 성분 해설이 역할·효능과 주의 문장을 한 문단으로 섞어 보낸다 —
/// 사용자 가독성을 위해 주의 성격 문장("다만/단,/주의…")을 분리해
/// 「주의사항」 소제목 아래로 옮긴다. 문장은 잃지 않는다(재배치만).
abstract final class InsightSectionPolicy {
  static final _cautionStart = RegExp(r'^(다만|단,|단 |주의)');

  static ({String role, String? caution}) splitRoleCaution(String text) {
    final sentences = text
        .split(RegExp(r'(?<=[.!?])\s+(?=[가-힣A-Za-z0-9])'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    final role = <String>[];
    final caution = <String>[];
    for (final s in sentences) {
      final isCaution = _cautionStart.hasMatch(s) ||
          s.contains('주의가 필요') ||
          s.contains('주의사항') ||
          s.contains('자극이 생길') ||
          s.contains('자극이 있을');
      (isCaution ? caution : role).add(s);
    }
    return (
      role: role.join(' '),
      caution: caution.isEmpty ? null : caution.join(' '),
    );
  }
}
