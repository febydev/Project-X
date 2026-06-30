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

extension StatsCharts on StatsService {
  List<DateTime> _lastDays(int days) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(days, (i) => today.subtract(Duration(days: days - 1 - i)));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Total sleep hours per day for the last [days] days (oldest → newest).
  List<double> dailySleepHours(List<LogEntry> entries, {int days = 7}) {
    final now = DateTime.now();
    return _lastDays(days).map((d) {
      var mins = 0;
      for (final s in entries.where((e) => e.type == LogType.sleep)) {
        if (!_sameDay(s.time, d)) continue;
        final end = s.endTime ?? (_sameDay(d, now) ? now : s.time);
        mins += end.difference(s.time).inMinutes;
      }
      return mins / 60.0;
    }).toList();
  }

  /// Feed counts per day for the last [days] days.
  List<double> dailyFeedCounts(List<LogEntry> entries, {int days = 7}) {
    return _lastDays(days).map((d) {
      return entries
          .where((e) => e.type == LogType.feed && _sameDay(e.time, d))
          .length
          .toDouble();
    }).toList();
  }

  /// Short labels (e.g. "Mo") for the last [days] days.
  List<String> dayLabels({int days = 7}) {
    const names = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return _lastDays(days).map((d) => names[(d.weekday - 1) % 7]).toList();
  }

  /// A warm weekly recap comparing the last 7 days to the previous 7.
  String weeklyRecap(List<LogEntry> entries, String name) {
    final now = DateTime.now();
    int sleepsIn(DateTime from, DateTime to) => entries
        .where((e) =>
            e.type == LogType.sleep &&
            e.time.isAfter(from) &&
            e.time.isBefore(to))
        .length;
    final thisWeek = sleepsIn(now.subtract(const Duration(days: 7)), now);
    final lastWeek = sleepsIn(now.subtract(const Duration(days: 14)),
        now.subtract(const Duration(days: 7)));
    if (thisWeek == 0 && lastWeek == 0) {
      return 'Keep logging and Mira will show $name\u2019s weekly trends here.';
    }
    final diff = thisWeek - lastWeek;
    if (diff > 0) return '$name had $diff more sleeps than last week 🌙';
    if (diff < 0) return '$name had ${-diff} fewer sleeps than last week.';
    return '$name\u2019s sleep was steady vs last week. 🌿';
  }
}
