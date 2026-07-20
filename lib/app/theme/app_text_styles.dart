import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 앱 타이포그래피.
///
/// - 본문/UI = Pretendard (테마 기본 fontFamily로 지정됨 → 대부분 여기 스타일 없이도 적용)
/// - 포인트 = 갈무리 9/11 (제목·타입코드 등 강조에만). [point9]/[point11] 사용.
///
/// 크기 스케일은 8pt 기반. 화면에서 fontSize를 직접 쓰지 말고 여기 상수를 참조한다.
class AppTextStyles {
  const AppTextStyles._();

  static const String _body = 'Pretendard';
  // 포인트 서체는 Galmuri9만 쓴다. (Galmuri11은 획이 거칠어 한글 제목에 부적합)
  static const String _point9 = 'Galmuri9';
  // 영문 전용 굵은 포인트. Galmuri9에는 Bold 파일이 없어 w700을 줘도 굵어지지 않는다.
  // Galmuri11만 Bold(700)를 가지므로, 영문 강조에는 이쪽을 쓴다.
  // (한글에는 쓰지 말 것 — 획이 거칠어 깨져 보인다)
  static const String _point11 = 'Galmuri11';

  // ---- 본문 (Pretendard) ----
  /// 큰 제목 (화면 상단 헤드라인)
  static const TextStyle headline = TextStyle(
    fontFamily: _body,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  /// 섹션 제목
  static const TextStyle title = TextStyle(
    fontFamily: _body,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  /// 본문
  static const TextStyle body = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  /// 보조 텍스트 (설명·캡션)
  static const TextStyle caption = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// 버튼 라벨
  static const TextStyle button = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // ---- 포인트 (갈무리 픽셀 폰트) ----
  //
  // 갈무리 제목은 아래 3단계로만 쓴다. 화면에서 size를 직접 넣지 말고
  // pointLg / pointMd / pointSm 을 쓴다 (일관성). 기본 색은 딥 네이비.
  //
  //   pointLg (44) — 화면 주인공 타이틀 (BSTI, 큰 브랜드 워딩)
  //   pointMd (30) — 섹션 강조 타이틀 (My skin i-TEM, TEST START)
  //   pointSm (17) — 버튼 라벨·작은 포인트
  //
  // 셋 다 Galmuri9를 쓴다. (11보다 획이 부드러워 한글 제목이 덜 거칠다)

  /// 갈무리 대형 타이틀 (44).
  static TextStyle pointLg({Color? color}) => _point(_point9, 44, color);

  /// 갈무리 중형 타이틀 (30).
  static TextStyle pointMd({Color? color}) => _point(_point9, 30, color);

  /// 갈무리 소형 — 버튼 라벨 등 (17).
  static TextStyle pointSm({Color? color}) => _point(_point9, 17, color);

  /// 갈무리 **굵게** — 영문 전용 (BSTI, O·S·P·W 같은 알파벳).
  ///
  /// Galmuri11 Bold를 쓴다. 한글에는 쓰지 말 것 (획이 거칠어 깨져 보인다).
  /// 크기는 호출부에서 정한다 — 영문 강조는 화면마다 스케일이 달라서.
  static TextStyle pointBoldEn({required double size, Color? color}) =>
      _point(_point11, size, color);

  static TextStyle _point(String family, double size, Color? color) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color ?? AppColors.primaryDark,
    );
  }
}
