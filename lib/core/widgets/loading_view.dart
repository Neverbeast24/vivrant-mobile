import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_motion.dart';

/// Centered branded pulse for full-screen or panel loading.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    Widget ring = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.accent.withValues(alpha: c.dark ? 0.22 : 0.14),
      ),
    );
    if (!VivrantMotion.reduce(context)) {
      ring = ring
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(0.82, 0.82),
            end: const Offset(1.14, 1.14),
            duration: 1400.ms,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.4, end: 1, duration: 1400.ms);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: ring),
                  Icon(Icons.spa_rounded, color: c.accent, size: 28),
                ],
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
