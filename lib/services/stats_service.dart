import '../models/log_entry.dart';
import '../theme/category_colors.dart';

/// A single computed statistic with a gentle severity colour.
class Stat {
  Stat({
    required this.label,
    required this.value,
    required this.detail,
    required this.severity,
    required this.type,
  });
  final String label;
  final String value;
  final String detail;
  final Severity severity;
  final LogType type;
}

/// Turns raw logs into Huckleberry-style summary stats with age-aware
/// "typical range" severity. NOT medical advice — amber means
/// "different from usual", never "something is wrong".
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  // ---- Age-based TYPICAL ranges (general guidance, not medical) ----
  ({int low, int high}) _sleepRange(int m) {
    if (m < 4) return (low: 14, high: 17);
    if (m < 12) return (low: 12, high: 15);
    if (m < 24) return (low: 11, high: 14);
    return (low: 10, high: 13);
  }

  ({int low, int high}) _feedRange(int m) {
    if (m < 1) return (low: 8, high: 12);
    if (m < 4) return (low: 6, high: 10);
    if (m < 6) return (low: 5, high: 8);
    if (m < 12) return (low: 4, high: 6);
    return (low: 3, high: 5);
  }

  Severity _sev(num value, ({int low, int high}) range) {
    if (value < range.low || value > range.high) return Severity.watch;
    return Severity.typical;
  }

  List<LogEntry> _last24(List<LogEntry> e) {
    final now = DateTime.now();
    return e
        .where((x) => now.difference(x.time) <= const Duration(hours: 24))
        .toList();
  }

  /// Total sleep minutes in the last 24h (uses endTime when present).
  int _sleepMinutes24(List<LogEntry> e) {
    final now = DateTime.now();
    var total = 0;
    for (final s in e.where((x) => x.type == LogType.sleep)) {
      final end = s.endTime ?? now;
      if (now.difference(s.time) > const Duration(hours: 24)) continue;
      total += end.difference(s.time).inMinutes;
    }
    return total;
  }

  String _hm(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}m';
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  List<Stat> summary(List<LogEntry> entries, int ageMonths) {
    final last24 = _last24(entries);
    final feeds = last24.where((e) => e.type == LogType.feed).length;
    final naps = last24.where((e) => e.type == LogType.sleep).length;
    final diapers = last24.where((e) => e.type == LogType.diaper).length;
    final sleepMin = _sleepMinutes24(entries);

    final sleepRange = _sleepRange(ageMonths);
    final feedRange = _feedRange(ageMonths);

    final hasData = entries.isNotEmpty;

    return [
      Stat(
        type: LogType.sleep,
        label: 'Sleep · 24h',
        value: _hm(sleepMin),
        detail: '$naps sleeps · typical ${sleepRange.low}–${sleepRange.high}h',
        severity: !hasData || sleepMin == 0
            ? Severity.unknown
            : _sev(sleepMin / 60.0, sleepRange),
      ),
      Stat(
        type: LogType.feed,
        label: 'Feeds · 24h',
        value: '$feeds',
        detail: 'typical ${feedRange.low}–${feedRange.high}/day',
        severity: !hasData ? Severity.unknown : _sev(feeds, feedRange),
      ),
      Stat(
        type: LogType.diaper,
        label: 'Diapers · 24h',
        value: '$diapers',
        detail: _diaperSplit(last24),
        severity: !hasData
            ? Severity.unknown
            : (diapers < 4 ? Severity.watch : Severity.typical),
      ),
    ];
  }

  String _diaperSplit(List<LogEntry> last24) {
    final d = last24.where((e) => e.type == LogType.diaper);
    var wet = 0, dirty = 0;
    for (final x in d) {
      final kind = x.details['kind'] as String?;
      if (kind == 'wet') wet++;
      if (kind == 'dirty') dirty++;
      if (kind == 'both') {
        wet++;
        dirty++;
      }
    }
    if (wet == 0 && dirty == 0) return 'wet / dirty';
    return '$wet wet · $dirty dirty';
  }

  /// A plain-language "current situation" line for the home screen.
  String situation(List<LogEntry> entries, int ageMonths, String name) {
    if (entries.isEmpty) return 'Start logging to see how $name\u2019s day is going.';
    final sleepMin = _sleepMinutes24(entries);
    final range = _sleepRange(ageMonths);
    final hours = sleepMin / 60.0;
    if (sleepMin == 0) return '$name hasn\u2019t had logged sleep in the last 24h.';
    if (hours < range.low) {
      return '$name has had less sleep than usual today — an earlier wind-down may help.';
    }
    if (hours > range.high) return '$name has been a sleepy one today. 🌙';
    return '$name\u2019s day looks right on track. 🌿';
  }
}
