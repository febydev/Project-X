import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/app_state.dart';
import '../../models/log_entry.dart';
import '../../services/pdf_service.dart';
import '../../services/stats_service.dart';
import '../../theme/category_colors.dart';
import '../../theme/mira_palette.dart';
import '../../widgets/soft_card.dart';
import '../paywall/paywall_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _state = AppState.instance;
  int _tab = 1; // 0 Day, 1 Week, 2 List, 3 Summary
  bool _exporting = false;

  static const _tabs = ['Day', 'Week', 'List', 'Summary'];

  Future<void> _exportPdf() async {
    if (!_state.premium) {
      PaywallScreen.softShow(context, 'Pediatrician reports');
      return;
    }
    final profile = _state.profile;
    if (profile == null) return;
    setState(() => _exporting = true);
    HapticFeedback.mediumImpact();
    try {
      await PdfService.instance
          .generateAndShare(profile: profile, entries: _state.entries);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Row(
                    children: [
                      Text('Timeline', style: text.displaySmall),
                      const Spacer(),
                      IconButton(
                        onPressed: _exporting ? null : _exportPdf,
                        icon: _exporting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4))
                            : Icon(Icons.ios_share_rounded, color: p.inkSoft),
                      ),
                    ],
                  ),
                ),
                _Segmented(
                  tabs: _tabs,
                  index: _tab,
                  onChange: (i) => setState(() => _tab = i),
                ),
                Expanded(child: _body()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return _listView(onlyToday: true);
      case 2:
        return _listView(onlyToday: false);
      case 3:
        return _SummaryView(state: _state);
      default:
        return _WeekGrid(entries: _state.entries);
    }
  }

  Widget _listView({required bool onlyToday}) {
    final entries = onlyToday ? _state.today : _state.entries;
    if (entries.isEmpty) {
      return Center(
        child: Text('Nothing logged yet.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: context.palette.inkSoft)),
      );
    }
    final grouped = <String, List<LogEntry>>{};
    for (final e in entries) {
      grouped.putIfAbsent(DateFormat('EEEE, MMM d').format(e.time), () => [])
          .add(e);
    }
    final text = Theme.of(context).textTheme;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        for (final day in grouped.keys) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
            child: Text(day, style: text.titleLarge),
          ),
          ...grouped[day]!.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EntryRow(entry: e),
              )),
        ],
      ],
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented(
      {required this.tabs, required this.index, required this.onChange});
  final List<String> tabs;
  final int index;
  final void Function(int) onChange;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: p.accentContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChange(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: index == i ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(tabs[i],
                        style: text.labelLarge?.copyWith(
                            color: index == i ? p.ink : p.inkSoft)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final sub = entry.type == LogType.sleep && entry.endTime != null
        ? '${entry.durationMinutes} min'
        : (entry.details['kind'] as String?) ?? '';
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration:
                BoxDecoration(color: entry.type.softColor, shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: entry.type.darkColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.label, style: text.titleMedium),
                if (sub.isNotEmpty)
                  Text(sub, style: text.bodyMedium?.copyWith(fontSize: 12)),
              ],
            ),
          ),
          Text(DateFormat('h:mm a').format(entry.time),
              style: text.bodyMedium?.copyWith(color: p.inkFaint)),
        ],
      ),
    );
  }
}

// ---------------- Week color-block grid ----------------
class _WeekGrid extends StatelessWidget {
  const _WeekGrid({required this.entries});
  final List<LogEntry> entries;

  static const double _hourPx = 22;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final days = List.generate(
        7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: [
        Row(
          children: [
            const SizedBox(width: 40),
            for (final d in days)
              Expanded(
                child: Column(
                  children: [
                    Text(DateFormat('E').format(d).substring(0, 2),
                        style: text.bodyMedium?.copyWith(fontSize: 11)),
                    Text('${d.day}',
                        style: text.labelLarge?.copyWith(
                            color: d.day == now.day ? p.accent : p.inkSoft)),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 24 * _hourPx,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // hour axis
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    for (int h = 0; h < 24; h += 3)
                      SizedBox(
                        height: _hourPx * 3,
                        child: Text(_hourLabel(h),
                            style: text.bodyMedium?.copyWith(fontSize: 10)),
                      ),
                  ],
                ),
              ),
              for (final d in days)
                Expanded(child: _DayColumn(day: d, entries: entries)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Tap a block in the day view for details.',
            style: text.bodyMedium, textAlign: TextAlign.center),
      ],
    );
  }

  String _hourLabel(int h) {
    if (h == 0) return '12am';
    if (h < 12) return '${h}am';
    if (h == 12) return '12pm';
    return '${h - 12}pm';
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.day, required this.entries});
  final DateTime day;
  final List<LogEntry> entries;

  static const double _hourPx = 22;

  bool _sameDay(DateTime a) =>
      a.year == day.year && a.month == day.month && a.day == day.day;

  double _y(DateTime t) => (t.hour * 60 + t.minute) / 60.0 * _hourPx;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dayEntries = entries.where((e) => _sameDay(e.time)).toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: p.accentContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          // sleep blocks
          for (final e in dayEntries.where((e) => e.type == LogType.sleep))
            Positioned(
              top: _y(e.time),
              left: 2,
              right: 2,
              height: e.endTime != null
                  ? ((e.endTime!.difference(e.time).inMinutes) / 60.0 * _hourPx)
                      .clamp(4.0, 24 * _hourPx)
                  : 8.0,
              child: Container(
                decoration: BoxDecoration(
                    color: CategoryColors.sleep,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
          // feed markers
          for (final e in dayEntries.where((e) => e.type == LogType.feed))
            Positioned(
              top: _y(e.time),
              left: 2,
              right: 2,
              height: 4,
              child: Container(color: CategoryColors.feed),
            ),
          // diaper markers
          for (final e in dayEntries.where((e) => e.type == LogType.diaper))
            Positioned(
              top: _y(e.time),
              left: 2,
              right: 2,
              height: 4,
              child: Container(color: CategoryColors.diaper),
            ),
        ],
      ),
    );
  }
}

// ---------------- Summary (stats + severity) ----------------
class _SummaryView extends StatelessWidget {
  const _SummaryView({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final stats =
        StatsService.instance.summary(state.entries, state.ageMonths);
    final labels = StatsService.instance.dayLabels();
    final sleepHours = StatsService.instance.dailySleepHours(state.entries);
    final feedCounts = StatsService.instance.dailyFeedCounts(state.entries);
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        _TrendChart(
          title: 'Sleep · hours per day',
          values: sleepHours,
          labels: labels,
          color: CategoryColors.sleep,
          suffix: 'h',
        ),
        const SizedBox(height: 12),
        _TrendChart(
          title: 'Feeds per day',
          values: feedCounts,
          labels: labels,
          color: CategoryColors.feed,
        ),
        const SizedBox(height: 18),
        for (final s in stats) ...[
          SoftCard(
            child: Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                      color: s.type.softColor, shape: BoxShape.circle),
                  child: Icon(s.type.icon, color: s.type.darkColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label, style: text.bodyMedium),
                      Text(s.value,
                          style: text.headlineSmall
                              ?.copyWith(color: s.type.darkColor)),
                      Text(s.detail,
                          style: text.bodyMedium?.copyWith(fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: s.severity.soft,
                      borderRadius: BorderRadius.circular(30)),
                  child: Text(s.severity.label,
                      style: text.labelLarge?.copyWith(
                          color: s.severity.color, fontSize: 10)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        Text(
          'Colors show how today compares to the typical range for your baby\u2019s age — '
          'not a medical judgement. Always check with your pediatrician for concerns.',
          style: text.bodyMedium?.copyWith(color: p.inkFaint, fontSize: 12),
        ),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({
    required this.title,
    required this.values,
    required this.labels,
    required this.color,
    this.suffix = '',
  });
  final String title;
  final List<double> values;
  final List<String> labels;
  final Color color;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final maxV = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxV <= 0 ? 1.0 : maxV * 1.25);
    final latest = values.isEmpty ? 0.0 : values.last;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: text.titleMedium)),
              Text(
                '${latest.toStringAsFixed(suffix == 'h' ? 1 : 0)}$suffix',
                style: text.titleLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: ((values.length - 1).clamp(1, 999)).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i],
                              style: text.bodyMedium
                                  ?.copyWith(fontSize: 10, color: p.inkFaint)),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.30),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
