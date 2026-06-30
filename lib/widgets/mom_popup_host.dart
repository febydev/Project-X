import 'package:flutter/material.dart';

import '../controllers/mom_controller.dart';
import '../models/mom_state.dart';
import 'mom_character.dart';
import 'mom_effects.dart';

/// Overlays the full-body mascot in the TOP-RIGHT corner (Clash-of-Clans style)
/// whenever a reaction is triggered, then slides her away. Place once near the
/// top of the widget tree (in the app shell).
class MomPopupHost extends StatefulWidget {
  const MomPopupHost({super.key});

  @override
  State<MomPopupHost> createState() => _MomPopupHostState();
}

class _MomPopupHostState extends State<MomPopupHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _curve =
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);

  MomState? _state;

  @override
  void initState() {
    super.initState();
    MomController.reaction.addListener(_onReaction);
  }

  void _onReaction() {
    final r = MomController.reaction.value;
    if (r != null) {
      setState(() => _state = r);
      _c.forward(from: 0);
    } else {
      _c.reverse();
    }
  }

  @override
  void dispose() {
    MomController.reaction.removeListener(_onReaction);
    _c.dispose();
    super.dispose();
  }

  String _bubble(MomState s) => switch (s) {
        MomState.celebrate => 'Logged! 🎉',
        MomState.shh => 'Shhh… sweet dreams 💤',
        MomState.surprised => 'Someone\u2019s awake! ☀️',
        MomState.diaper => 'All fresh! ✨',
        MomState.pointing => 'Nap time soon ⏰',
        MomState.hug => 'You\u2019ve got this 💛',
        MomState.calm => 'Breathe with me',
        MomState.tired => 'Time to rest 🌙',
        MomState.idle => '',
      };

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final s = _state;
    if (s == null) return const SizedBox.shrink();

    return Positioned(
      top: topInset + 8,
      right: 6,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) {
          final v = _curve.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: v.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset((1 - v) * 180, 0),
              child: child,
            ),
          );
        },
        child: IgnorePointer(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_bubble(s).isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  margin: const EdgeInsets.only(right: 4, top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: Text(
                    _bubble(s),
                    style: const TextStyle(
                        color: Color(0xFF2A2E2B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
              SizedBox(
                width: 150,
                height: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MomEffects(state: s, size: 190),
                    MomCharacter(state: s, width: 140, height: 180),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
