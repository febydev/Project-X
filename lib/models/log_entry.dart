import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The kinds of things a parent logs.
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

/// A single logged event, stored on-device.
class LogEntry {
  LogEntry({
    required this.id,
    required this.type,
    required this.time,
    this.note,
  });

  final String id;
  final LogType type;
  final DateTime time;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'time': time.toIso8601String(),
        'note': note,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        id: json['id'] as String,
        type: LogType.values.firstWhere((e) => e.name == json['type']),
        time: DateTime.parse(json['time'] as String),
        note: json['note'] as String?,
      );
}
