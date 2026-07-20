import 'package:flutter/material.dart';

/// cosmos 브랜드 색상 팔레트.
///
/// 피그마 "Color Chart"(Page 2, node 87:2027)에서 추출한 실제 값이다.
/// 디자인 확정 시 아래 값만 교체하면 전체 톤이 따라온다.
class AppColors {
  const AppColors._();

  /// Material 3 ColorScheme 생성을 위한 시드 컬러. (메인 블루)
  static const Color seed = Color(0xFF7490D2);

  // 브랜드 컬러
  static const Color primary = Color(0xFF7490D2); // 메인 블루
  static const Color primaryDark = Color(0xFF112D55); // 딥 네이비 (헤드라인·로고 텍스트)
  static const Color primaryLight = Color(0xFFC0D7F8); // 연블루 (배경·칩)
  static const Color accent = Color(0xFFFCAB43); // 오렌지 포인트 (강조·CTA)
  static const Color background = Color(0xFFFAFAFA); // 배경 화이트
  static const Color surface = Color(0xFFFFFFFF);

  // 성분 안전도 배지 등 시맨틱 컬러
  static const Color safe = Color(0xFF4CAF7D);
  static const Color caution = Color(0xFFFCAB43); // 포인트 오렌지와 통일
  static const Color danger = Color(0xFFE07A5F);

  static const Color textPrimary = Color(0xFF3B3939); // 차콜
  static const Color textSecondary = Color(0xFF8A8A8A); // 보조 텍스트 (가독성 확보)
  static const Color outline = Color(0xFFCAC4D0); // 라벤더 그레이 (보더·구분선)
}
