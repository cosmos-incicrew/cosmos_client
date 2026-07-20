import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// cosmos 앱의 Material 3 테마.
///
/// 라이트/다크 테마를 시드 컬러 기반으로 생성하되, 브랜드 색(primary·accent 등)을
/// 명시적으로 매핑한다. 컴포넌트별 세부 스타일(버튼·카드·칩 라운드)도 여기서 통일한다.
/// 색·타이포 값의 근거는 docs/design-system.md.
class AppTheme {
  const AppTheme._();

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // 시드로 파생색을 만들되, 브랜드 핵심 색은 직접 덮어써 디자인과 일치시킨다.
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    ).copyWith(
      primary: AppColors.primary, // 메인 블루
      secondary: AppColors.accent, // 오렌지 포인트 (CTA·강조)
      surface: isLight ? AppColors.surface : null,
      outlineVariant: isLight ? AppColors.outline : null,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.background : colorScheme.surface,
      fontFamily: 'Pretendard', // 본문 기본 폰트
      textTheme: _textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        // 기능 화면들이 답답하지 않게 상단 바 높이를 넉넉히.
        toolbarHeight: 88,
        scrolledUnderElevation: 0.5,
        backgroundColor:
            isLight ? AppColors.background : colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: AppTextStyles.title.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? Colors.white : colorScheme.surfaceContainerHighest,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isLight ? AppColors.primaryLight : null,
        labelStyle: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  /// AppTextStyles 를 Material TextTheme 슬롯에 연결한다.
  /// (Text 위젯에 style 을 안 줘도 이 매핑이 기본 적용됨)
  static TextTheme _textTheme(ColorScheme cs) {
    final onSurface = cs.onSurface;
    return TextTheme(
      headlineMedium: AppTextStyles.headline.copyWith(color: onSurface),
      titleLarge: AppTextStyles.title.copyWith(color: onSurface),
      titleMedium: AppTextStyles.title.copyWith(fontSize: 16, color: onSurface),
      bodyLarge: AppTextStyles.body.copyWith(color: onSurface),
      bodyMedium: AppTextStyles.body.copyWith(color: onSurface),
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
    );
  }
}
