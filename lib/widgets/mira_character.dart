import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/mom_anim.dart';

/// Mira's animated mom character — warm, tired-but-happy, and REACTIVE.
///
/// Code-drawn (CustomPainter + animation) for now. When you supply a Lottie
/// `.json`, swap the `_paint` body for a Lottie player keyed on [_current];
/// the state machine here already drives which animation should play.
class MiraCharacter extends StatefulWidget {
  const MiraCharacter({
    super.key,
    required this.events,
    this.size = 96,
    this.sleeping = false,
  });

  /// Emits one-shot reactions (feed, diaper, shhh, …).
  final ValueListenable<MomAnim> events;

  /// Approx width in logical px (height ≈ size * 1.25).
  final double size;

  /// If a sleep timer is running, base idle becomes "shhh"-ish calm.
  final bool sleeping;

  @override
  State<MiraCharacter> createState() => _MiraCharacterState();
}

class _MiraCharacterState extends State<MiraCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  MomAnim _current = MomAnim.idle;
  Timer? _revertTimer;

  static const _transient = {
    MomAnim.celebrate,
    MomAnim.diaper,
    MomAnim.shhh,
    MomAnim.wake,
    MomAnim.pointClock,
    MomAnim.dance,
    MomAnim.leap,
  };

  @override
  void initState() {
    super.initState();
    _current = _baseIdle();
    widget.events.addListener(_onEvent);
  }

  void _onEvent() {
    final a = widget.events.value;
    setState(() => _current = a);
    _revertTimer?.cancel();
    if (_transient.contains(a)) {
      _revertTimer = Timer(const Duration(milliseconds: 2600), () {
        if (mounted) setState(() => _current = _baseIdle());
      });
    }
  }

  MomAnim _baseIdle() {
    if (widget.sleeping) return MomAnim.shhh;
    final h = DateTime.now().hour;
    if (h >= 22 || h < 5) return MomAnim.bedtime;
    if (h < 11) return MomAnim.idleMorning;
    if (h >= 19) return MomAnim.idleNight;
    return MomAnim.idle;
  }

  @override
  void dispose() {
    widget.events.removeListener(_onEvent);
    _revertTimer?.cancel();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * 1.28,
      child: AnimatedBuilder(
        animation: _loop,
        builder: (context, _) => CustomPaint(
          painter: _MomPainter(t: _loop.value, state: _current),
        ),
      ),
    );
  }
}

class _MomPainter extends CustomPainter {
  _MomPainter({required this.t, required this.state});
  final double t; // 0..1 loop
  final MomAnim state;

  // palette
  static const skin = Color(0xFFF3C9A8);
  static const skinShade = Color(0xFFE3B492);
  static const hair = Color(0xFF6D4C41);
  static const cardigan = Color(0xFF4E6E5D);
  static const cardiganDark = Color(0xFF3C5749);
  static const cheek = Color(0xFFEFA9A0);

  double _sin(double phase) => math.sin((t * 2 * math.pi) + phase);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // gentle bob / breathing
    final breathing = state == MomAnim.calm;
    final bob = (breathing ? _sin(0) * 2.5 : _sin(0) * 1.5);
    canvas.translate(0, bob);

    final headR = w * 0.26;
    final headCy = h * 0.30;
    final bodyTop = headCy + headR * 0.7;

    // ---- body / cardigan ----
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [cardigan, cardiganDark],
      ).createShader(Rect.fromLTWH(cx - w * 0.3, bodyTop, w * 0.6, h * 0.6));
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(cx - w * 0.28, bodyTop, w * 0.56, h * 0.55),
      topLeft: Radius.circular(w * 0.28),
      topRight: Radius.circular(w * 0.28),
      bottomLeft: const Radius.circular(18),
      bottomRight: const Radius.circular(18),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // ---- arms (pose by state) ----
    _drawArms(canvas, w, h, cx, bodyTop);

    // ---- accessories behind/near ----
    _drawAccessory(canvas, w, h, cx, headCy, headR, bodyTop);

    // ---- hair bun ----
    final hairPaint = Paint()..color = hair;
    canvas.drawCircle(Offset(cx, headCy - headR * 0.95), headR * 0.42, hairPaint);
    // hair frame
    canvas.drawCircle(Offset(cx, headCy), headR * 1.04, hairPaint);

    // ---- head ----
    canvas.drawCircle(Offset(cx, headCy), headR, Paint()..color = skin);
    // chin shade
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, headCy + headR * 0.1), radius: headR),
      0.4,
      2.34,
      false,
      Paint()
        ..color = skinShade.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // ---- cheeks ----
    final cheekPaint = Paint()..color = cheek.withValues(alpha: 0.55);
    canvas.drawCircle(
        Offset(cx - headR * 0.5, headCy + headR * 0.18), headR * 0.16, cheekPaint);
    canvas.drawCircle(
        Offset(cx + headR * 0.5, headCy + headR * 0.18), headR * 0.16, cheekPaint);

    // ---- glasses + eyes ----
    _drawFace(canvas, cx, headCy, headR);
  }

  void _drawFace(Canvas canvas, double cx, double cy, double r) {
    final eyeY = cy - r * 0.05;
    final dx = r * 0.42;
    final ink = Paint()
      ..color = const Color(0xFF3A322E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final sleepy = state == MomAnim.bedtime ||
        state == MomAnim.idleNight ||
        state == MomAnim.shhh;
    final happy = state == MomAnim.celebrate ||
        state == MomAnim.dance ||
        state == MomAnim.idleMorning;

    // glasses
    final glass = Paint()
      ..color = const Color(0xFF3A322E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(cx - dx, eyeY), r * 0.26, glass);
    canvas.drawCircle(Offset(cx + dx, eyeY), r * 0.26, glass);
    canvas.drawLine(Offset(cx - dx + r * 0.26, eyeY),
        Offset(cx + dx - r * 0.26, eyeY), glass);

    // eyes
    if (sleepy) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx - dx, eyeY), radius: r * 0.12),
          0.2, 2.7, false, ink);
      canvas.drawArc(
          Rect.fromCircle(center: Offset(cx + dx, eyeY), radius: r * 0.12),
          0.2, 2.7, false, ink);
    } else {
      canvas.drawCircle(
          Offset(cx - dx, eyeY), 2.4, Paint()..color = const Color(0xFF3A322E));
      canvas.drawCircle(
          Offset(cx + dx, eyeY), 2.4, Paint()..color = const Color(0xFF3A322E));
    }

    // mouth
    final mouthY = cy + r * 0.45;
    if (state == MomAnim.shhh) {
      // small "o" + finger handled in arms
      canvas.drawCircle(Offset(cx, mouthY), r * 0.07,
          Paint()..color = const Color(0xFF7A4B45));
    } else if (state == MomAnim.bedtime || state == MomAnim.idleMorning) {
      // yawn (open oval)
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(cx, mouthY), width: r * 0.28, height: r * 0.4),
          Paint()..color = const Color(0xFF7A4B45));
    } else {
      final smile = happy ? r * 0.5 : r * 0.32;
      final path = Path()
        ..moveTo(cx - r * 0.22, mouthY)
        ..quadraticBezierTo(cx, mouthY + smile, cx + r * 0.22, mouthY);
      canvas.drawPath(path, ink);
    }
  }

  void _drawArms(
      Canvas canvas, double w, double h, double cx, double bodyTop) {
    final arm = Paint()
      ..color = cardiganDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;
    final hand = Paint()..color = skin;

    final shoulderY = bodyTop + h * 0.06;
    final lsh = Offset(cx - w * 0.24, shoulderY);
    final rsh = Offset(cx + w * 0.24, shoulderY);

    // default rest positions
    Offset lHand = Offset(cx - w * 0.30, shoulderY + h * 0.18);
    Offset rHand = Offset(cx + w * 0.30, shoulderY + h * 0.18);

    switch (state) {
      case MomAnim.celebrate:
        rHand = Offset(cx + w * 0.28, shoulderY - h * 0.18 + _sin(0) * 4);
        break;
      case MomAnim.dance:
        lHand = Offset(cx - w * 0.34, shoulderY - h * 0.12 + _sin(0) * 6);
        rHand = Offset(cx + w * 0.34, shoulderY - h * 0.12 + _sin(math.pi) * 6);
        break;
      case MomAnim.wake:
      case MomAnim.hug:
        lHand = Offset(cx - w * 0.40, shoulderY - h * 0.10);
        rHand = Offset(cx + w * 0.40, shoulderY - h * 0.10);
        break;
      case MomAnim.shhh:
        rHand = Offset(cx + w * 0.04, h * 0.30); // finger to lips
        break;
      case MomAnim.pointClock:
        rHand = Offset(cx + w * 0.42, shoulderY - h * 0.04);
        break;
      case MomAnim.calm:
        lHand = Offset(cx - w * 0.08, shoulderY + h * 0.10);
        rHand = Offset(cx + w * 0.08, shoulderY + h * 0.10);
        break;
      case MomAnim.diaper:
        rHand = Offset(cx + w * 0.06, h * 0.34); // hand near nose
        break;
      case MomAnim.leap:
        rHand = Offset(cx + w * 0.22, shoulderY - h * 0.20);
        break;
      default:
        break;
    }

    canvas.drawLine(lsh, lHand, arm);
    canvas.drawLine(rsh, rHand, arm);
    canvas.drawCircle(lHand, w * 0.07, hand);
    canvas.drawCircle(rHand, w * 0.07, hand);
  }

  void _drawAccessory(Canvas canvas, double w, double h, double cx,
      double headCy, double headR, double bodyTop) {
    switch (state) {
      case MomAnim.idleMorning:
        // coffee cup near left hand
        final c = Offset(cx - w * 0.30, bodyTop + h * 0.20);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: c, width: w * 0.18, height: h * 0.10),
              const Radius.circular(4)),
          Paint()..color = Colors.white,
        );
        // steam
        final steam = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(Offset(c.dx, c.dy - h * 0.06),
            Offset(c.dx + _sin(0) * 3, c.dy - h * 0.11), steam);
        break;
      case MomAnim.idleNight:
      case MomAnim.bedtime:
        // soft night-light glow
        canvas.drawCircle(
          Offset(cx + w * 0.34, bodyTop + h * 0.18),
          w * 0.14,
          Paint()..color = const Color(0xFFFFE0A3).withValues(alpha: 0.5),
        );
        break;
      case MomAnim.leap:
        // little "brain" bubble above
        final b = Offset(cx + w * 0.28, headCy - headR * 1.4);
        canvas.drawCircle(b, w * 0.12, Paint()..color = const Color(0xFFCBA6E0));
        break;
      case MomAnim.pointClock:
        // clock icon
        final cc = Offset(cx + w * 0.44, headCy);
        canvas.drawCircle(cc, w * 0.12, Paint()..color = Colors.white);
        final hands = Paint()
          ..color = const Color(0xFF3A322E)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(cc, cc.translate(0, -w * 0.07), hands);
        canvas.drawLine(cc, cc.translate(w * 0.05, 0), hands);
        break;
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _MomPainter old) =>
      old.t != t || old.state != state;
}
