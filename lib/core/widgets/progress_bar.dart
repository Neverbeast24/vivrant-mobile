import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

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
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: VivrantColors.ink.withValues(alpha: 0.08)),
            FractionallySizedBox(
              widthFactor: clamped,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: VivrantColors.brandGradient,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
