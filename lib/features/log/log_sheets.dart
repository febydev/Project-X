import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/mom_controller.dart';
import '../../data/app_state.dart';
import '../../models/mom_state.dart';
import '../../theme/category_colors.dart';
import '../../theme/mira_palette.dart';

/// Fast, one-handed bottom sheets for diaper / feed / growth logging.
class LogSheets {
  LogSheets._();

  static Future<void> _show(BuildContext context, Widget child) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _SheetShell(child: child),
      ),
    );
  }

  static void diaper(BuildContext context) {
    _show(context, const _DiaperSheet());
  }

  static void feed(BuildContext context) {
    _show(context, const _FeedSheet());
  }

  static void growth(BuildContext context) {
    _show(context, const _GrowthSheet());
  }
}

class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 44,
            decoration: BoxDecoration(
                color: p.hairline, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DiaperSheet extends StatelessWidget {
  const _DiaperSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final opts = const [
      ('wet', 'Wet', Icons.water_drop_rounded),
      ('dirty', 'Dirty', Icons.cloud_rounded),
      ('both', 'Both', Icons.done_all_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log a diaper', style: text.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final o in opts) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AppState.instance.addDiaper(o.$1);
                    MomController.trigger(MomState.diaper);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: CategoryColors.diaperSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Icon(o.$3, color: CategoryColors.diaperDark, size: 28),
                        const SizedBox(height: 8),
                        Text(o.$2,
                            style: text.titleMedium
                                ?.copyWith(color: CategoryColors.diaperDark)),
                      ],
                    ),
                  ),
                ),
              ),
              if (o != opts.last) const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _FeedSheet extends StatefulWidget {
  const _FeedSheet();
  @override
  State<_FeedSheet> createState() => _FeedSheetState();
}

class _FeedSheetState extends State<_FeedSheet> {
  String _side = 'L';
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final sides = const [('L', 'Left'), ('R', 'Right'), ('bottle', 'Bottle')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log a feeding', style: text.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final s in sides) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _side = s.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _side == s.$1
                          ? CategoryColors.feed
                          : CategoryColors.feedSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(s.$2,
                          style: text.titleMedium?.copyWith(
                              color: _side == s.$1
                                  ? Colors.white
                                  : CategoryColors.feedDark)),
                    ),
                  ),
                ),
              ),
              if (s != sides.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 14),
        if (_side == 'bottle')
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (ml) — optional',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CategoryColors.feed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: () {
              HapticFeedback.lightImpact();
              final ml = int.tryParse(_amount.text);
              AppState.instance.addFeed(details: {
                'side': _side,
                if (ml != null) 'amountMl': ml,
              });
              Navigator.pop(context);
            },
            child: const Text('Save feeding'),
          ),
        ),
        SizedBox(height: p.isDark ? 0 : 0),
      ],
    );
  }
}

class _GrowthSheet extends StatefulWidget {
  const _GrowthSheet();
  @override
  State<_GrowthSheet> createState() => _GrowthSheetState();
}

class _GrowthSheetState extends State<_GrowthSheet> {
  final _weight = TextEditingController();
  final _height = TextEditingController();

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Log growth', style: text.titleLarge),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _height,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: CategoryColors.growth,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            onPressed: () {
              HapticFeedback.lightImpact();
              AppState.instance.addGrowth(
                weightKg: double.tryParse(_weight.text),
                heightCm: double.tryParse(_height.text),
              );
              Navigator.pop(context);
            },
            child: const Text('Save growth'),
          ),
        ),
      ],
    );
  }
}
