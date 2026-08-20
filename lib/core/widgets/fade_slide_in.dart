import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vivrant_motion.dart';

/// One-shot fade + rise used for headers, cards, and list rows.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 0.045,
    this.duration = VivrantMotion.slow,
  });

  final Widget child;
  final Duration delay;
  final double offset;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (VivrantMotion.reduce(context)) return child;
    return child
        .animate()
        .fadeIn(
          delay: delay,
          duration: duration,
          curve: Curves.easeOut,
        )
        .slideY(
          begin: offset,
          end: 0,
          delay: delay,
          duration: duration,
          curve: VivrantMotion.enter,
        );
  }
}

/// Staggered fade+rise for [ListView] / [Column] children.
List<Widget> staggerAppear(
  List<Widget> children, {
  int intervalMs = VivrantMotion.staggerMs,
  int startMs = 40,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeSlideIn(
        delay: Duration(milliseconds: startMs + i * intervalMs),
        child: children[i],
      ),
  ];
}
