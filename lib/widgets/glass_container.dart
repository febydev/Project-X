import 'dart:ui';

import 'package:flutter/material.dart';

/// A frosted-glass surface (iOS-style). Used sparingly — only the floating
/// nav bar — because live blur is GPU-heavy. One blur layer keeps even
/// average phones smooth.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.radius = 30,
    this.blur = 18,
    this.opacity = 0.72,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
