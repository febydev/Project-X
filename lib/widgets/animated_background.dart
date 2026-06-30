import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mira_palette.dart';

/// A slow, smooth gradient that drifts behind the app content, tinted by the
/// active palette (e.g. Midnight = light-blue → deep-blue). Cards sit on top
/// with their own solid colours; only this backdrop animates. Cheap enough for
/// average phones (one shader, ~24s loop).
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tint = p.isDark ? 0.45 : 0.16;
    final cA = Color.lerp(p.background, p.accent, tint)!;
    final cB = p.background;
    final cC = Color.lerp(p.background, p.accentDark, tint * 0.8)!;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final a = _c.value * 2 * math.pi;
        final begin = Alignment(math.cos(a), math.sin(a));
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: begin,
              end: Alignment(-begin.x, -begin.y),
              colors: [cA, cB, cC],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        );
      },
    );
  }
}
