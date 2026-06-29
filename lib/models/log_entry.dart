import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The kinds of things a parent logs. Phase 1 keeps it to the core three.
enum LogType { feed, sleep, diaper }

extension LogTypeX on LogType {
  String get label => switch (this) {
        LogType.feed => 'Feed',
        LogType.sleep => 'Sleep',
        LogType.diaper => 'Diaper',
      };

  IconData get icon => switch (this) {
        LogType.feed => Icons.local_cafe_rounded,
        LogType.sleep => Icons.bedtime_rounded,
        LogType.diaper => Icons.water_drop_rounded,
      };

  Color get color => switch (this) {
        LogType.feed => AppColors.feed,
        LogType.sleep => AppColors.sleep,
        LogType.diaper => AppColors.diaper,
      };

  Color get softColor => switch (this) {
        LogType.feed => AppColors.feedSoft,
        LogType.sleep => AppColors.sleepSoft,
        LogType.diaper => AppColors.diaperSoft,
      };
}

/// A single logged event. Persistence comes in Phase 2 — for now it lives
/// in memory so we can build and feel the UI.
class LogEntry {
  LogEntry({
    required this.type,
    required this.time,
    this.note,
  });

  final LogType type;
  final DateTime time;
  final String? note;
}
