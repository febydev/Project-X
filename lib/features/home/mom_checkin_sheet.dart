import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../models/mom_anim.dart';
import '../../theme/mira_palette.dart';

/// Gentle morning check-in for the parent. Dismissible instantly.
class MomCheckinSheet extends StatefulWidget {
  const MomCheckinSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MomCheckinSheet(),
    );
  }

  @override
  State<MomCheckinSheet> createState() => _MomCheckinSheetState();
}

class _MomCheckinSheetState extends State<MomCheckinSheet> {
  int _sleep = 0, _mood = 0, _body = 0;

  bool get _ready => _sleep > 0 && _mood > 0 && _body > 0;

  void _save() {
    HapticFeedback.lightImpact();
    AppState.instance.addCheckin(_sleep, _mood, _body);
    if (AppState.instance.lowStreak >= 3) {
      AppState.instance.emitCharacter(MomAnim.hug);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 5,
              width: 44,
              decoration: BoxDecoration(
                  color: p.hairline, borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 18),
          Text('Good morning 💛', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text('A quick check-in — for you, not the baby.',
              style: text.bodyMedium),
          const SizedBox(height: 20),
          _Row(
            label: '😴 How did YOU sleep?',
            value: _sleep,
            onPick: (v) => setState(() => _sleep = v),
          ),
          const SizedBox(height: 16),
          _Row(
            label: '😊 How\u2019s your mood?',
            value: _mood,
            onPick: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: 16),
          _Row(
            label: '💪 How\u2019s your body feeling?',
            value: _body,
            onPick: (v) => setState(() => _body = v),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              onPressed: _ready ? _save : null,
              child: const Text('Save check-in'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: p.inkSoft),
              child: const Text('Maybe later'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.onPick});
  final String label;
  final int value;
  final void Function(int) onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.titleMedium),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onPick(i);
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: value == i ? primary : p.card,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: value == i ? primary : p.hairline, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('$i',
                      style: text.titleMedium?.copyWith(
                          color: value == i ? Colors.white : p.inkSoft)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
