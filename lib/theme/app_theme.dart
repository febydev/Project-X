import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Central theme for Mira. Material 3, Plus Jakarta Sans, soft and spacious.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.sage,
      onPrimary: Colors.white,
      secondary: AppColors.apricot,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      surfaceContainerLowest: AppColors.cream,
      surfaceContainerLow: AppColors.sand,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.sand,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(baseText),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.5,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: AppColors.ink,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: AppColors.inkSoft,
        height: 1.45,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
    );
  }
}
