import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A simple, warm wordmark/icon for Mira — a soft leaf inside a gradient
/// rounded square. Stands in for an app icon and brand moments.
class MiraLogo extends StatelessWidget {
  const MiraLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppGradient>()!.linear;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Icon(Icons.spa_rounded, color: Colors.white, size: size * 0.5),
    );
  }
}
