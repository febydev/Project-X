import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'mira_palette.dart';

/// Central theme for Mira. Material 3, Plus Jakarta Sans, fully driven by the
/// selected [MiraPalette] so switching themes retints the entire UI.
class AppTheme {
  AppTheme._();

  static ThemeData fromPalette(MiraPalette p) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.brightness,
    ).copyWith(
      primary: p.accent,
      onPrimary: Colors.white,
      secondary: AppColors.apricot,
      surface: p.surface,
      onSurface: p.ink,
      surfaceContainerLowest: p.card,
      surfaceContainerLow: p.background,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: p.brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: p.background,
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme(baseText, p),
      extensions: [p, AppGradient(p.accent, p.accentDark)],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: p.ink,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
    );
  }

  static TextTheme _textTheme(TextTheme base, MiraPalette p) {
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.5),
      headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.5),
      headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.3),
      titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: p.ink, letterSpacing: -0.2),
      titleMedium: base.titleMedium
          ?.copyWith(fontWeight: FontWeight.w600, color: p.ink),
      bodyLarge: base.bodyLarge?.copyWith(color: p.ink, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(color: p.inkSoft, height: 1.45),
      labelLarge: base.labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );
  }
}

/// Exposes the current accent's gradient to widgets (buttons, hero cards).
class AppGradient extends ThemeExtension<AppGradient> {
  const AppGradient(this.start, this.end);
  final Color start;
  final Color end;

  LinearGradient get linear => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end],
      );

  @override
  AppGradient copyWith({Color? start, Color? end}) =>
      AppGradient(start ?? this.start, end ?? this.end);

  @override
  AppGradient lerp(ThemeExtension<AppGradient>? other, double t) {
    if (other is! AppGradient) return this;
    return AppGradient(
      Color.lerp(start, other.start, t)!,
      Color.lerp(end, other.end, t)!,
    );
  }
}
