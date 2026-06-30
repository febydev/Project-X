import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/mom_state.dart';

/// A short, one-shot particle burst layered behind/around the mascot pop-in so
/// reactions feel alive (confetti, hearts, sparkles, "zzz", etc.).
class MomEffects extends StatefulWidget {
  const MomEffects({super.key, required this.state, this.size = 220});
  final MomState state;
  final double size;

  @override
  State<MomEffects> createState() => _MomEffectsState();
}

class _MomEffectsState extends State<MomEffects>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..forward();

  final _rand = math.Random();
  late final List<_P> _particles = _make();

  List<_P> _make() {
    final n = switch (widget.state) {
      MomState.celebrate => 22,
      MomState.hug => 12,
      MomState.surprised => 10,
      MomState.shh => 6,
      _ => 12,
    };
    return List.generate(n, (i) {
      return _P(
        angle: _rand.nextDouble() * math.pi * 2,
        speed: 0.4 + _rand.nextDouble() * 0.6,
        hue: _rand.nextDouble(),
        spin: (_rand.nextDouble() - 0.5) * 6,
        seed: _rand.nextDouble(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _EffectPainter(
                t: _c.value, state: widget.state, particles: _particles),
          ),
        ),
      ),
    );
  }
}

class _P {
  _P({
    required this.angle,
    required this.speed,
    required this.hue,
    required this.spin,
    required this.seed,
  });
  final double angle, speed, hue, spin, seed;
}

class _EffectPainter extends CustomPainter {
  _EffectPainter(
      {required this.t, required this.state, required this.particles});
  final double t;
  final MomState state;
  final List<_P> particles;

  static const _confetti = [
    Color(0xFF00BCD4),
    Color(0xFFFF7043),
    Color(0xFFFFA726),
    Color(0xFF66BB6A),
    Color(0xFFB889C9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.45);
    final fade = (1 - t).clamp(0.0, 1.0);

    switch (state) {
      case MomState.celebrate:
      case MomState.surprised:
        for (var i = 0; i < particles.length; i++) {
          final p = particles[i];
          final dist = t * size.width * 0.5 * p.speed;
          final pos = center +
              Offset(math.cos(p.angle) * dist,
                  math.sin(p.angle) * dist + t * t * 60);
          final paint = Paint()
            ..color = _confetti[i % _confetti.length].withValues(alpha: fade);
          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(p.spin * t * math.pi);
          canvas.drawRect(
              Rect.fromCenter(center: Offset.zero, width: 8, height: 12), paint);
          canvas.restore();
        }
        break;
      case MomState.hug:
        for (final p in particles) {
          final y = size.height * 0.8 - t * size.height * 0.6 * p.speed;
          final x = size.width / 2 + math.sin((t + p.seed) * 6) * 26;
          _heart(canvas, Offset(x, y), 9 + p.seed * 5,
              const Color(0xFFEF7C8E).withValues(alpha: fade));
        }
        break;
      case MomState.shh:
        final tp = TextPainter(textDirection: TextDirection.ltr);
        for (var i = 0; i < particles.length; i++) {
          final p = particles[i];
          final y = center.dy - t * 70 - i * 14;
          final x = center.dx + 30 + math.sin((t + p.seed) * 4) * 14;
          tp.text = TextSpan(
              text: 'z',
              style: TextStyle(
                  color: const Color(0xFF7C8DB5).withValues(alpha: fade),
                  fontSize: 18 + i * 4,
                  fontWeight: FontWeight.bold));
          tp.layout();
          tp.paint(canvas, Offset(x, y));
        }
        break;
      default:
        // gentle sparkles (diaper, growth, pointing, calm, idle, tired)
        for (var i = 0; i < particles.length; i++) {
          final p = particles[i];
          final dist = t * size.width * 0.4 * p.speed;
          final pos = center +
              Offset(math.cos(p.angle) * dist, math.sin(p.angle) * dist);
          final r = (2 + p.seed * 3) * (1 - t);
          canvas.drawCircle(
              pos,
              r.clamp(0.0, 6.0),
              Paint()
                ..color = Colors.white.withValues(alpha: fade * 0.9));
        }
    }
  }

  void _heart(Canvas canvas, Offset c, double s, Color color) {
    final path = Path();
    path.moveTo(c.dx, c.dy + s * 0.3);
    path.cubicTo(c.dx - s, c.dy - s * 0.6, c.dx - s * 0.5, c.dy - s,
        c.dx, c.dy - s * 0.3);
    path.cubicTo(c.dx + s * 0.5, c.dy - s, c.dx + s, c.dy - s * 0.6,
        c.dx, c.dy + s * 0.3);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _EffectPainter old) => old.t != t;
}
