import 'package:flutter/material.dart';

/// Mira's palette — calm, warm and grown-up.
/// We deliberately avoid the cliché pastel pink/blue "default baby app" look.
/// Warm sand backgrounds, a deep sage primary, and a soft apricot accent.
class AppColors {
  AppColors._();

  // Neutrals
  static const Color sand = Color(0xFFF6F3EE); // app background
  static const Color cream = Color(0xFFFDFBF8); // raised surfaces
  static const Color surface = Color(0xFFFFFFFF); // cards

  // Brand
  static const Color sage = Color(0xFF4E6E5D); // primary
  static const Color sageDark = Color(0xFF3C5749);
  static const Color sageContainer = Color(0xFFDDE7E0);

  // Accent
  static const Color apricot = Color(0xFFE5A878);
  static const Color apricotSoft = Color(0xFFF6E6D7);

  // Text
  static const Color ink = Color(0xFF2A2E2B); // primary text
  static const Color inkSoft = Color(0xFF727A74); // secondary text
  static const Color inkFaint = Color(0xFFA7AEA8); // tertiary / hints

  // Activity categories
  static const Color feed = Color(0xFFE0A26B); // warm amber
  static const Color feedSoft = Color(0xFFF7E7D6);
  static const Color sleep = Color(0xFF7C8DB5); // twilight blue
  static const Color sleepSoft = Color(0xFFE2E7F1);
  static const Color diaper = Color(0xFF6FB0A6); // teal
  static const Color diaperSoft = Color(0xFFDDEDEA);

  // Misc
  static const Color hairline = Color(0xFFEAE6DF);
  static const Color shadow = Color(0x14000000);
}
