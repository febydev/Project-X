import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/app_state.dart';
import '../../models/log_entry.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import '../paywall/paywall_screen.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final AppState _state = AppState.instance;
  bool _exporting = false;

  Future<void> _exportPdf() async {
    if (!_state.premium) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
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

  Map<String, List<LogEntry>> _grouped(List<LogEntry> entries) {
    final map = <String, List<LogEntry>>{};
    for (final e in entries) {
      final key = DateFormat('EEEE, MMM d').format(e.time);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  int _countLast7(LogType type) {
    final from = DateTime.now().subtract(const Duration(days: 7));
    return _state.entries
        .where((e) => e.type == type && e.time.isAfter(from))
        .length;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            final entries = _state.entries;
            final grouped = _grouped(entries);
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                  sliver: SliverList.list(
                    children: [
                      Text('Timeline', style: text.displaySmall),
                      const SizedBox(height: 4),
                      Text('The story of your days, all on your phone.',
                          style: text.bodyMedium),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _Insight(
                              label: 'Feeds · 7d',
                              value: _countLast7(LogType.feed),
                              color: AppColors.feed),
                          const SizedBox(width: 10),
                          _Insight(
                              label: 'Sleeps · 7d',
                              value: _countLast7(LogType.sleep),
                              color: AppColors.sleep),
                          const SizedBox(width: 10),
                          _Insight(
                              label: 'Diapers · 7d',
                              value: _countLast7(LogType.diaper),
                              color: AppColors.diaper),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ExportCard(
                          exporting: _exporting,
                          premium: _state.premium,
                          onTap: _exportPdf),
                      const SizedBox(height: 22),
                      if (entries.isEmpty)
                        SoftCard(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text('No history yet.',
                                style: text.titleMedium
                                    ?.copyWith(color: AppColors.inkSoft)),
                          ),
                        )
                      else
                        for (final day in grouped.keys) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
                            child: Text(day, style: text.titleLarge),
                          ),
                          ...grouped[day]!.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _Row(entry: e),
                            ),
                          ),
                        ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Insight extends StatelessWidget {
  const _Insight(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text('$value',
                style: text.headlineMedium?.copyWith(color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: text.bodyMedium?.copyWith(fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard(
      {required this.exporting, required this.premium, required this.onTap});
  final bool exporting;
  final bool premium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      onTap: exporting ? null : onTap,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: const BoxDecoration(
                color: AppColors.sageContainer, shape: BoxShape.circle),
            child: exporting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: AppColors.sageDark),
                  )
                : const Icon(Icons.picture_as_pdf_rounded,
                    color: AppColors.sageDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pediatrician report', style: text.titleMedium),
                const SizedBox(height: 2),
                Text('Export the last 7 days as a clean PDF.',
                    style: text.bodyMedium),
              ],
            ),
          ),
          if (!premium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.apricotSoft,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text('Premium',
                  style: text.labelLarge
                      ?.copyWith(color: AppColors.apricot, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
                color: entry.type.softColor, shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: entry.type.color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(entry.type.label, style: text.titleMedium)),
          Text(DateFormat('h:mm a').format(entry.time),
              style: text.bodyMedium?.copyWith(color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}
