import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_motion.dart';

/// Accent-filled progress track (goals, pantry stock, budgets).
class VivrantProgressBar extends StatelessWidget {
  const VivrantProgressBar({
    super.key,
    required this.value,
    this.height = 8,
  });

  /// 0.0 – 1.0
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: c.ink.withValues(alpha: 0.08)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clamped),
              duration: VivrantMotion.reduce(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: VivrantMotion.emphasized,
              builder: (context, animated, _) {
                return FractionallySizedBox(
                  widthFactor: animated,
                  child: Container(
                    decoration: BoxDecoration(gradient: c.brandGradient),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
