import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_motion.dart';

/// Slow-drifting botanical glows behind page content.
class AmbientOrbs extends StatelessWidget {
  const AmbientOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final reduce = VivrantMotion.reduce(context);
    final top = _Orb(
      size: 240,
      color: c.accent.withValues(alpha: c.dark ? 0.18 : 0.11),
    );
    final mid = _Orb(
      size: 200,
      color: c.cyan.withValues(alpha: c.dark ? 0.14 : 0.08),
    );
    final low = _Orb(
      size: 170,
      color: c.accentDeep.withValues(alpha: c.dark ? 0.12 : 0.06),
    );

    Widget drift(
      Widget orb, {
      required Offset end,
      required double scale,
      required Duration duration,
    }) {
      if (reduce) return orb;
      return orb
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .move(
            begin: Offset.zero,
            end: end,
            duration: duration,
            curve: Curves.easeInOut,
          )
          .scale(
            begin: const Offset(1, 1),
            end: Offset(scale, scale),
            duration: duration,
            curve: Curves.easeInOut,
          );
    }

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: drift(
              top,
              end: const Offset(-12, 18),
              scale: 1.08,
              duration: const Duration(milliseconds: 7200),
            ),
          ),
          Positioned(
            top: 240,
            left: -110,
            child: drift(
              mid,
              end: const Offset(16, -14),
              scale: 1.06,
              duration: const Duration(milliseconds: 8600),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -60,
            child: drift(
              low,
              end: const Offset(-10, -16),
              scale: 1.1,
              duration: const Duration(milliseconds: 9800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
