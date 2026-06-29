import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../services/ai_service.dart';
import '../../models/chat_message.dart';
import '../../theme/category_colors.dart';
import '../../theme/mira_palette.dart';
import '../../widgets/soft_card.dart';

/// One age-appropriate activity per day. Generated via the AI proxy, with a
/// gentle on-device fallback so the card is never empty.
class DailyActivityCard extends StatefulWidget {
  const DailyActivityCard({super.key});

  @override
  State<DailyActivityCard> createState() => _DailyActivityCardState();
}

class _DailyActivityCardState extends State<DailyActivityCard> {
  final _state = AppState.instance;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensure());
  }

  Future<void> _ensure() async {
    if (!_state.needsNewActivity) return;
    if (_state.profile == null) return;
    final weeks = (_state.ageMonths * 4.345).round();

    if (_state.proxyUrl.isEmpty) {
      _state.setActivity(_fallback(weeks));
      return;
    }
    setState(() => _loading = true);
    final res = await AiService.instance.send(
      proxyUrl: _state.proxyUrl,
      history: [
        ChatMessage(
            text:
                'Suggest ONE short play activity for my baby (about $weeks weeks old) '
                'for today. One sentence, with the developmental benefit.',
            fromMira: false)
      ],
      babyName: _state.babyName,
      ageMonths: _state.ageMonths,
      mode: 'activity',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _state.setActivity(res.ok ? res.reply! : _fallback(weeks));
  }

  String _fallback(int weeks) {
    if (weeks < 12) {
      return 'Hold a high-contrast toy 8–10 inches from your baby\u2019s face and move it slowly side to side for 30 seconds. Supports visual tracking.';
    }
    if (weeks < 26) {
      return 'Place a toy just out of reach during tummy time to encourage reaching and rolling. Builds core strength.';
    }
    if (weeks < 52) {
      return 'Play peekaboo a few times today. It teaches object permanence and brings lots of giggles.';
    }
    return 'Name objects as you point to them around the room. Narrating like this grows early language fast.';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final done = _state.activityDone;
        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: const BoxDecoration(
                        color: CategoryColors.growthSoft,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.child_friendly_rounded,
                        color: CategoryColors.growthDark, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text("Today's activity", style: text.titleMedium),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(
                      color: CategoryColors.growth,
                      backgroundColor: CategoryColors.growthSoft),
                )
              else
                Text(_state.activityText ?? '…', style: text.bodyLarge),
              const SizedBox(height: 14),
              if (done)
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: CategoryColors.growth),
                    const SizedBox(width: 8),
                    Text('Nice work today!',
                        style: text.titleMedium
                            ?.copyWith(color: CategoryColors.growthDark)),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: CategoryColors.growth,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _state.markActivityDone();
                        },
                        child: const Text('We did it ✓'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(foregroundColor: p.inkSoft),
                      child: const Text('Save for later'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
