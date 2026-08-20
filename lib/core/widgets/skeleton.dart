import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_layout.dart';
import '../theme/vivrant_motion.dart';

/// Shimmering placeholder block used while a module is loading.
class VivrantSkeleton extends StatelessWidget {
  const VivrantSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 12,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final bar = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: c.ink.withValues(alpha: c.dark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (VivrantMotion.reduce(context)) return bar;
    return bar
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1400.ms,
          color: c.accent.withValues(alpha: c.dark ? 0.18 : 0.14),
        );
  }
}

/// Two-card skeleton that matches [StatCard] + a row.
class SkeletonFeed extends StatelessWidget {
  const SkeletonFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    Widget card() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.ink.withValues(alpha: 0.06)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VivrantSkeleton(width: 88, height: 12),
            SizedBox(height: 16),
            VivrantSkeleton(width: 140, height: 28, radius: 10),
            SizedBox(height: 12),
            VivrantSkeleton(width: 180, height: 12),
          ],
        ),
      );
    }

    return Column(
      children: [
        card(),
        const TileGap(),
        card(),
        const TileGap(),
        card(),
      ],
    );
  }
}
