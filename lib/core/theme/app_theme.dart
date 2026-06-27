import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get light => _theme(Brightness.light);
  static ThemeData get dark => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF17150F) : AppColors.bg;
    final surface = isDark ? const Color(0xFF201C15) : AppColors.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.espresso,
        brightness: brightness,
        surface: surface,
        onSurface: isDark ? Colors.white : AppColors.ink,
      ),
      dividerColor: isDark ? const Color(0xFF2E2920) : AppColors.hairline,
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: AppTypography.h1,
        titleLarge: AppTypography.h2,
        titleMedium: AppTypography.h3,
        bodyLarge: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelSmall: AppTypography.label,
      ),
    );
  }

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0D2B2418), // 0.05 opacity
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x382B2418), // 0.22 opacity
      blurRadius: 22,
      spreadRadius: -15,
      offset: Offset(0, 10),
    ),
  ];
}
