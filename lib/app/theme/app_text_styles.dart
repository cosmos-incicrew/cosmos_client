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
  static const String _point9 = 'Galmuri9';
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
  /// 갈무리 9 — 작은 포인트 라벨 (태그·뱃지·소제목 강조)
  static TextStyle point9({double size = 14, Color? color, FontWeight? weight}) {
    return TextStyle(
      fontFamily: _point9,
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.primary,
    );
  }

  /// 갈무리 11 — 큰 포인트 타이틀 (BSTI 타입코드, 브랜드명 등 강조)
  static TextStyle point11({double size = 28, Color? color, FontWeight? weight}) {
    return TextStyle(
      fontFamily: _point11,
      fontSize: size,
      fontWeight: weight ?? FontWeight.w700,
      color: color ?? AppColors.primary,
    );
  }
}
