import 'package:flutter/material.dart';

/// Fixed brand colors per category — used CONSISTENTLY everywhere (cards,
/// timeline blocks, stats), Huckleberry-style. These are independent of the
/// app theme so a "Sleep" thing is always teal, "Feeding" always orange, etc.
class CategoryColors {
  CategoryColors._();

  // Sleep = teal/cyan
  static const Color sleep = Color(0xFF00BCD4);
  static const Color sleepDark = Color(0xFF0097A7);
  static const Color sleepSoft = Color(0xFFE0F7FA);

  // Feeding = warm orange
  static const Color feed = Color(0xFFFF7043);
  static const Color feedDark = Color(0xFFE64A19);
  static const Color feedSoft = Color(0xFFFFE5DC);

  // Diaper = golden yellow
  static const Color diaper = Color(0xFFFFA726);
  static const Color diaperDark = Color(0xFFF57C00);
  static const Color diaperSoft = Color(0xFFFFF1DC);

  // Growth = green
  static const Color growth = Color(0xFF66BB6A);
  static const Color growthDark = Color(0xFF43A047);
  static const Color growthSoft = Color(0xFFE3F4E4);

  // Developmental leap = soft purple
  static const Color leap = Color(0xFF9575CD);
  static const Color leapSoft = Color(0xFFEDE7F6);
}

/// Severity = how far a stat is from the typical range for the baby's age.
/// NEVER a medical judgement — green "typical", amber "different from usual".
enum Severity { typical, watch, unknown }

extension SeverityX on Severity {
  Color get color => switch (this) {
        Severity.typical => const Color(0xFF66BB6A), // green
        Severity.watch => const Color(0xFFFFB300), // amber
        Severity.unknown => const Color(0xFFB0B7BD), // grey
      };

  Color get soft => switch (this) {
        Severity.typical => const Color(0xFFE6F4E7),
        Severity.watch => const Color(0xFFFFF3D6),
        Severity.unknown => const Color(0xFFECEFF1),
      };

  String get label => switch (this) {
        Severity.typical => 'Typical',
        Severity.watch => 'Different from usual',
        Severity.unknown => 'Keep logging',
      };
}
