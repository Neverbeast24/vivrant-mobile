import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/widgets/widgets.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return GradientScaffold(
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _BrandHeroMark(),
              const SizedBox(height: 28),
              VivrantBrand(dark: dark),
              const SizedBox(height: 36),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: dark ? VivrantColors.darkAccent : VivrantColors.accent,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large mark with a concentric radial glow (aligned to the mark center).
class _BrandHeroMark extends StatelessWidget {
  const _BrandHeroMark();

  static const double _markSize = 112;
  static const double _glowSize = 220;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final glow = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final reduce = VivrantMotion.reduce(context);

    Widget halo = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.55,
          colors: [
            glow.withValues(alpha: dark ? 0.42 : 0.28),
            glow.withValues(alpha: dark ? 0.14 : 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: const SizedBox.expand(),
    );
    if (!reduce) {
      halo = halo
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.08, 1.08),
            duration: 2200.ms,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.7, end: 1, duration: 2200.ms);
    }

    Widget mark = Container(
      width: _markSize,
      height: _markSize,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: 0,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/brand/vivrant-mark.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.spa_rounded,
          size: 48,
          color: glow,
        ),
      ),
    );
    if (!reduce) {
      mark = mark
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(
            begin: const Offset(0.86, 0.86),
            end: const Offset(1, 1),
            duration: 640.ms,
            curve: VivrantMotion.spring,
          );
    }

    return SizedBox(
      width: _glowSize,
      height: _glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: halo),
          mark,
        ],
      ),
    );
  }
}
