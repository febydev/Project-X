import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mom_state.dart';

/// Displays the animated WebP mom mascot for a given [MomState], with a 300ms
/// cross-fade between states and extra Flutter motion on top of the WebP.
class MomCharacter extends StatefulWidget {
  const MomCharacter({super.key, required this.state});
  final MomState state;

  @override
  State<MomCharacter> createState() => _MomCharacterState();
}

class _MomCharacterState extends State<MomCharacter>
    with SingleTickerProviderStateMixin {
  // Drives the repeating motions (idle bob, calm breathe).
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: Image.asset(
        widget.state.asset,
        key: ValueKey(widget.state),
        width: 120,
        height: 160,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );

    Widget animated;
    switch (widget.state) {
      case MomState.idle:
        // very subtle bob up/down ~2px over 3s, repeating
        animated = AnimatedBuilder(
          animation: _loop,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, math.sin(_loop.value * 2 * math.pi) * 1.0),
            child: child,
          ),
          child: image,
        );
        break;
      case MomState.calm:
        // slow gentle breathe scale 1.0 → 1.03 → 1.0, repeating (~2s feel)
        animated = AnimatedBuilder(
          animation: _loop,
          builder: (context, child) {
            final s = 1.0 +
                0.015 * (1 - math.cos(_loop.value * 2 * math.pi));
            return Transform.scale(scale: s, child: child);
          },
          child: image,
        );
        break;
      case MomState.celebrate:
        // one-shot scale pulse 1.0 → 1.12 → 1.0 over 400ms
        animated = TweenAnimationBuilder<double>(
          key: const ValueKey('celebrate'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 400),
          builder: (context, t, child) {
            final s = 1.0 + 0.12 * math.sin(t * math.pi);
            return Transform.scale(scale: s, child: child);
          },
          child: image,
        );
        break;
      case MomState.surprised:
        // quick horizontal shake (3 fast oscillations)
        animated = TweenAnimationBuilder<double>(
          key: const ValueKey('surprised'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 420),
          builder: (context, t, child) {
            final dx = math.sin(t * math.pi * 6) * 3 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: image,
        );
        break;
      default:
        animated = image; // diaper, shh, pointing, hug, tired → just fade
    }

    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: animated),
    );
  }
}
