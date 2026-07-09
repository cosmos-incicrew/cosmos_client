import 'package:flutter/material.dart';

/// cosmos 브랜드 색상 팔레트.
///
/// 화장품/스킨케어 앱 톤에 맞춘 부드러운 그린 계열 시드 컬러입니다.
/// 실제 브랜드 컬러가 확정되면 [seed] 값만 바꾸면 전체 톤이 따라옵니다.
class AppColors {
  const AppColors._();

  /// Material 3 ColorScheme 생성을 위한 시드 컬러.
  static const Color seed = Color(0xFF5B8C5A); // sage green

  // 브랜드 포인트 컬러 (테마 밖에서 직접 참조할 때 사용)
  static const Color primary = Color(0xFF5B8C5A);
  static const Color secondary = Color(0xFFE8B4A0); // soft coral
  static const Color background = Color(0xFFFAF9F6); // warm white
  static const Color surface = Color(0xFFFFFFFF);

  // 성분 안전도 배지 등에 쓰는 시맨틱 컬러
  static const Color safe = Color(0xFF4CAF7D);
  static const Color caution = Color(0xFFE6B54A);
  static const Color danger = Color(0xFFE07A5F);

  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF7A7A7A);
}
