import 'package:flutter/material.dart';

/// A complete, swappable palette. Unlike a single accent, this retints the
/// ENTIRE UI — background, surfaces, text, accents — so each theme feels like
/// a different world. Includes warm/professional light sets and cinematic darks.
@immutable
class MiraPalette extends ThemeExtension<MiraPalette> {
  const MiraPalette({
    required this.name,
    required this.brightness,
    required this.background,
    required this.surface,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.hairline,
    required this.accent,
    required this.accentDark,
    required this.accentContainer,
    required this.onAccentContainer,
  });

  final String name;
  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color card;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color hairline;
  final Color accent;
  final Color accentDark;
  final Color accentContainer;
  final Color onAccentContainer;

  bool get isDark => brightness == Brightness.dark;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent, accentDark],
      );

  @override
  MiraPalette copyWith({
    String? name,
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? card,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? hairline,
    Color? accent,
    Color? accentDark,
    Color? accentContainer,
    Color? onAccentContainer,
  }) {
    return MiraPalette(
      name: name ?? this.name,
      brightness: brightness ?? this.brightness,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkFaint: inkFaint ?? this.inkFaint,
      hairline: hairline ?? this.hairline,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentContainer: accentContainer ?? this.accentContainer,
      onAccentContainer: onAccentContainer ?? this.onAccentContainer,
    );
  }

  @override
  MiraPalette lerp(ThemeExtension<MiraPalette>? other, double t) {
    if (other is! MiraPalette) return this;
    return MiraPalette(
      name: t < 0.5 ? name : other.name,
      brightness: t < 0.5 ? brightness : other.brightness,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      accentContainer: Color.lerp(accentContainer, other.accentContainer, t)!,
      onAccentContainer: Color.lerp(onAccentContainer, other.onAccentContainer, t)!,
    );
  }

  /// All available themes. Index 0 (Sage) is free; the rest are Premium.
  static const List<MiraPalette> all = [
    // --- Light / professional ---
    MiraPalette(
      name: 'Sage',
      brightness: Brightness.light,
      background: Color(0xFFF6F3EE),
      surface: Color(0xFFFFFFFF),
      card: Color(0xFFFFFFFF),
      ink: Color(0xFF2A2E2B),
      inkSoft: Color(0xFF727A74),
      inkFaint: Color(0xFFA7AEA8),
      hairline: Color(0xFFEAE6DF),
      accent: Color(0xFF4E6E5D),
      accentDark: Color(0xFF3C5749),
      accentContainer: Color(0xFFDDE7E0),
      onAccentContainer: Color(0xFF2E4034),
    ),
    MiraPalette(
      name: 'Slate',
      brightness: Brightness.light,
      background: Color(0xFFEEF1F4),
      surface: Color(0xFFFFFFFF),
      card: Color(0xFFFFFFFF),
      ink: Color(0xFF1F2933),
      inkSoft: Color(0xFF5B6670),
      inkFaint: Color(0xFF98A2AD),
      hairline: Color(0xFFE0E5EA),
      accent: Color(0xFF3E5C76),
      accentDark: Color(0xFF2C4257),
      accentContainer: Color(0xFFDCE6EE),
      onAccentContainer: Color(0xFF243B4E),
    ),
    MiraPalette(
      name: 'Golden',
      brightness: Brightness.light,
      background: Color(0xFFFBF1E5),
      surface: Color(0xFFFFFFFF),
      card: Color(0xFFFFFFFF),
      ink: Color(0xFF3A2E26),
      inkSoft: Color(0xFF8A7866),
      inkFaint: Color(0xFFB6A893),
      hairline: Color(0xFFEFE3D3),
      accent: Color(0xFFC98A53),
      accentDark: Color(0xFFA66E3C),
      accentContainer: Color(0xFFF6E6D2),
      onAccentContainer: Color(0xFF6E4A26),
    ),
    // --- Cinematic darks ---
    MiraPalette(
      name: 'Midnight',
      brightness: Brightness.dark,
      background: Color(0xFF11151C),
      surface: Color(0xFF1A2029),
      card: Color(0xFF1E2530),
      ink: Color(0xFFECEFF4),
      inkSoft: Color(0xFFA6AEBB),
      inkFaint: Color(0xFF6E7682),
      hairline: Color(0xFF2A323D),
      accent: Color(0xFF8AA0D8),
      accentDark: Color(0xFF5E72A8),
      accentContainer: Color(0xFF243044),
      onAccentContainer: Color(0xFFC9D4EC),
    ),
    MiraPalette(
      name: 'Forest',
      brightness: Brightness.dark,
      background: Color(0xFF0F1714),
      surface: Color(0xFF17211C),
      card: Color(0xFF1B2620),
      ink: Color(0xFFE9F0EA),
      inkSoft: Color(0xFF9FB0A6),
      inkFaint: Color(0xFF6B786F),
      hairline: Color(0xFF25322B),
      accent: Color(0xFF6FB68C),
      accentDark: Color(0xFF46795C),
      accentContainer: Color(0xFF1E2E26),
      onAccentContainer: Color(0xFFCDE6D6),
    ),
    MiraPalette(
      name: 'Plum',
      brightness: Brightness.dark,
      background: Color(0xFF161019),
      surface: Color(0xFF1F1726),
      card: Color(0xFF241B2C),
      ink: Color(0xFFF0EAF3),
      inkSoft: Color(0xFFB3A6BC),
      inkFaint: Color(0xFF7A6E82),
      hairline: Color(0xFF2E2438),
      accent: Color(0xFFB889C9),
      accentDark: Color(0xFF8A5C9B),
      accentContainer: Color(0xFF2A2034),
      onAccentContainer: Color(0xFFE3CFEC),
    ),
  ];
}

/// Convenience: `context.palette.accent`, etc.
extension PaletteContext on BuildContext {
  MiraPalette get palette =>
      Theme.of(this).extension<MiraPalette>() ?? MiraPalette.all.first;
}
