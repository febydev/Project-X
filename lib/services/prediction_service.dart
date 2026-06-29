import '../models/log_entry.dart';

class Prediction {
  Prediction({
    required this.ready,
    this.etaMinutes,
    this.at,
    this.progress = 0,
    this.confidence = '',
  });

  /// false → not enough data yet.
  final bool ready;
  final int? etaMinutes; // minutes from now (can be negative = overdue)
  final DateTime? at;
  final double progress; // 0..1 toward the predicted moment
  final String confidence;

  String get etaText {
    if (etaMinutes == null) return '';
    final m = etaMinutes!;
    if (m <= 0) return 'now';
    if (m < 60) return 'in ${m}m';
    final h = m ~/ 60, mm = m % 60;
    return mm == 0 ? 'in ${h}h' : 'in ${h}h ${mm}m';
  }

  String get atText {
    if (at == null) return '';
    final hour = at!.hour % 12 == 0 ? 12 : at!.hour % 12;
    final min = at!.minute.toString().padLeft(2, '0');
    final ampm = at!.hour < 12 ? 'AM' : 'PM';
    return '$hour:$min $ampm';
  }
}

/// On-device prediction engine. Needs ≥3 days of data before predicting.
class PredictionService {
  PredictionService._();
  static final PredictionService instance = PredictionService._();

  int daysOfData(List<LogEntry> entries) {
    final days = <String>{};
    for (final e in entries) {
      days.add('${e.time.year}-${e.time.month}-${e.time.day}');
    }
    return days.length;
  }

  bool hasEnough(List<LogEntry> entries) => daysOfData(entries) >= 3;

  /// Next feed based on rolling average of last 5 feed intervals.
  Prediction nextFeed(List<LogEntry> entries) {
    if (!hasEnough(entries)) return Prediction(ready: false);
    final feeds = entries.where((e) => e.type == LogType.feed).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (feeds.length < 3) return Prediction(ready: false);

    final intervals = <int>[];
    for (var i = feeds.length - 1; i > 0 && intervals.length < 5; i--) {
      intervals.add(feeds[i].time.difference(feeds[i - 1].time).inMinutes);
    }
    if (intervals.isEmpty) return Prediction(ready: false);
    final avg = intervals.reduce((a, b) => a + b) ~/ intervals.length;
    final last = feeds.last.time;
    final at = last.add(Duration(minutes: avg));
    final now = DateTime.now();
    final eta = at.difference(now).inMinutes;
    final elapsed = now.difference(last).inMinutes;
    return Prediction(
      ready: true,
      etaMinutes: eta,
      at: at,
      progress: (elapsed / avg).clamp(0.0, 1.0),
      confidence: 'Based on recent feeds',
    );
  }

  /// Next nap based on average wake window (awake gap before sleeps).
  Prediction nextNap(List<LogEntry> entries) {
    if (!hasEnough(entries)) return Prediction(ready: false);
    final sleeps = entries
        .where((e) => e.type == LogType.sleep && e.endTime != null)
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    if (sleeps.length < 2) return Prediction(ready: false);

    // wake window = time from one sleep's end to the next sleep's start
    final windows = <int>[];
    for (var i = sleeps.length - 1; i > 0 && windows.length < 5; i--) {
      final gap =
          sleeps[i].time.difference(sleeps[i - 1].endTime!).inMinutes;
      if (gap > 0 && gap < 600) windows.add(gap);
    }
    if (windows.isEmpty) return Prediction(ready: false);
    final avg = windows.reduce((a, b) => a + b) ~/ windows.length;

    final lastWake = sleeps.last.endTime!;
    final at = lastWake.add(Duration(minutes: avg));
    final now = DateTime.now();
    final eta = at.difference(now).inMinutes;
    final elapsed = now.difference(lastWake).inMinutes;
    return Prediction(
      ready: true,
      etaMinutes: eta,
      at: at,
      progress: (elapsed / avg).clamp(0.0, 1.0),
      confidence: 'Based on recent wake windows',
    );
  }
}
