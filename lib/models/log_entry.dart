import 'package:flutter/material.dart';

import '../theme/category_colors.dart';

/// Categories a parent logs. Growth is measurement-based; the rest are events.
enum LogType { feed, sleep, diaper, growth }

extension LogTypeX on LogType {
  String get label => switch (this) {
        LogType.feed => 'Feeding',
        LogType.sleep => 'Sleep',
        LogType.diaper => 'Diaper',
        LogType.growth => 'Growth',
      };

  IconData get icon => switch (this) {
        LogType.feed => Icons.local_cafe_rounded,
        LogType.sleep => Icons.bedtime_rounded,
        LogType.diaper => Icons.baby_changing_station_rounded,
        LogType.growth => Icons.straighten_rounded,
      };

  Color get color => switch (this) {
        LogType.feed => CategoryColors.feed,
        LogType.sleep => CategoryColors.sleep,
        LogType.diaper => CategoryColors.diaper,
        LogType.growth => CategoryColors.growth,
      };

  Color get darkColor => switch (this) {
        LogType.feed => CategoryColors.feedDark,
        LogType.sleep => CategoryColors.sleepDark,
        LogType.diaper => CategoryColors.diaperDark,
        LogType.growth => CategoryColors.growthDark,
      };

  Color get softColor => switch (this) {
        LogType.feed => CategoryColors.feedSoft,
        LogType.sleep => CategoryColors.sleepSoft,
        LogType.diaper => CategoryColors.diaperSoft,
        LogType.growth => CategoryColors.growthSoft,
      };

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [color, darkColor],
      );
}

/// A single logged event, stored on-device.
/// [endTime] is used by sleep (start→end). [details] holds optional extras:
/// sleep: {'startMood','howFellAsleep','endMood'}
/// diaper: {'kind': 'wet'|'dirty'|'both'}
/// feed:   {'side': 'L'|'R'|'bottle', 'amountMl': int}
/// growth: {'weightKg': double, 'heightCm': double}
class LogEntry {
  LogEntry({
    required this.id,
    required this.type,
    required this.time,
    this.endTime,
    this.note,
    Map<String, dynamic>? details,
  }) : details = details ?? {};

  final String id;
  final LogType type;
  final DateTime time;
  DateTime? endTime;
  String? note;
  final Map<String, dynamic> details;

  /// Sleep duration in minutes (0 if still running or not a sleep).
  int get durationMinutes {
    if (endTime == null) return 0;
    return endTime!.difference(time).inMinutes;
  }

  bool get isRunning => type == LogType.sleep && endTime == null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'time': time.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'note': note,
        'details': details,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        type: LogType.values.firstWhere((e) => e.name == json['type']),
        time: DateTime.parse(json['time'] as String),
        endTime: json['endTime'] == null
            ? null
            : DateTime.parse(json['endTime'] as String),
        note: json['note'] as String?,
        details: (json['details'] as Map?)?.cast<String, dynamic>() ?? {},
      );
}
