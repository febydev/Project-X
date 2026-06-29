import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../models/log_entry.dart';
import '../../theme/category_colors.dart';
import '../../theme/mira_palette.dart';

/// Huckleberry-style sleep entry: a big circular START/STOP timer plus
/// optional detail chips. Minimal, white, one-handed.
class AddSleepScreen extends StatefulWidget {
  const AddSleepScreen({super.key});

  @override
  State<AddSleepScreen> createState() => _AddSleepScreenState();
}

class _AddSleepScreenState extends State<AddSleepScreen> {
  final _state = AppState.instance;
  Timer? _ticker;
  final Set<String> _startTags = {};
  final Set<String> _endTags = {};

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _awakeText {
    final lastSleep = _state.lastOf(LogType.sleep);
    final base = lastSleep?.endTime;
    if (base == null) return '';
    final m = DateTime.now().difference(base).inMinutes;
    if (m < 60) return '${_state.babyName} has been up for ${m}m';
    return '${_state.babyName} has been up for ${m ~/ 60}h ${m % 60}m';
  }

  String _elapsed() {
    final s = _state.runningSleep;
    if (s == null) return '0:00';
    final d = DateTime.now().difference(s.time);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final sec = d.inSeconds % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _toggle() async {
    HapticFeedback.mediumImpact();
    if (_state.runningSleep == null) {
      await _state.startSleep();
      setState(() {});
    } else {
      await _state.stopSleep(details: {
        'startTags': _startTags.toList(),
        'endTags': _endTags.toList(),
      });
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final running = _state.runningSleep != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded)),
        title: Text(running ? 'End sleep' : 'Add sleep'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Center(
            child: Text(
              running ? 'Sleeping…' : _awakeText,
              style: text.bodyLarge?.copyWith(color: p.inkSoft),
            ),
          ),
          const SizedBox(height: 36),
          Center(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                height: 210,
                width: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [CategoryColors.sleep, CategoryColors.sleepDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: CategoryColors.sleep.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 12)),
                  ],
                  border: Border.all(
                      color: CategoryColors.sleep.withValues(alpha: 0.3),
                      width: 8),
                ),
                alignment: Alignment.center,
                child: Text(
                  running ? _elapsed() : 'START',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(running ? 'Tap to end' : 'Tap to start',
                style: text.bodyMedium),
          ),
          const SizedBox(height: 36),
          if (!running) ...[
            _section('START OF SLEEP', const [
              ('Long time to fall asleep', Icons.timer_outlined),
              ('Upset', Icons.sentiment_dissatisfied_rounded),
            ], _startTags),
          ] else ...[
            _section('END OF SLEEP', const [
              ('Woke up child', Icons.notifications_active_outlined),
              ('Upset', Icons.sentiment_dissatisfied_rounded),
            ], _endTags),
          ],
        ],
      ),
    );
  }

  Widget _section(
      String title, List<(String, IconData)> opts, Set<String> selected) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: text.labelLarge
                ?.copyWith(color: p.inkFaint, letterSpacing: 1)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final o in opts)
              GestureDetector(
                onTap: () => setState(() => selected.contains(o.$1)
                    ? selected.remove(o.$1)
                    : selected.add(o.$1)),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: selected.contains(o.$1)
                            ? CategoryColors.sleepSoft
                            : p.card,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected.contains(o.$1)
                              ? CategoryColors.sleep
                              : p.hairline,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(o.$2,
                          color: selected.contains(o.$1)
                              ? CategoryColors.sleepDark
                              : p.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 78,
                      child: Text(o.$1,
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(fontSize: 11)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
