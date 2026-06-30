import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mom_state.dart';

/// Displays the animated WebP mom mascot for a given [MomState].
/// Transparent background. When [halfBody] is true (home header) it crops to
/// the upper portion; otherwise it shows the full body (corner pop-in).
class MomCharacter extends StatefulWidget {
  const MomCharacter({
    super.key,
    required this.state,
    this.halfBody = false,
    this.width = 120,
    this.height = 160,
  });

  final MomState state;
  final bool halfBody;
  final double width;
  final double height;

  @override
  State<MomCharacter> createState() => _MomCharacterState();
}

class _MomCharacterState extends State<MomCharacter>
    with SingleTickerProviderStateMixin {
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
        width: widget.width,
        height: widget.height,
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
    );

    Widget animated;
    switch (widget.state) {
      case MomState.idle:
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
        animated = AnimatedBuilder(
          animation: _loop,
          builder: (context, child) {
            final s = 1.0 + 0.015 * (1 - math.cos(_loop.value * 2 * math.pi));
            return Transform.scale(scale: s, child: child);
          },
          child: image,
        );
        break;
      case MomState.celebrate:
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
        animated = image;
    }

    if (widget.halfBody) {
      return SizedBox(
        width: widget.width,
        child: ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: 0.6,
            child: animated,
          ),
        ),
      );
    }
    return animated;
  }
}
