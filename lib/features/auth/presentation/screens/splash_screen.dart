import 'package:flutter/material.dart';
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
              ),
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

    return SizedBox(
      width: _glowSize,
      height: _glowSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
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
          ),
          Container(
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
              errorBuilder: (_, __, ___) => const Icon(
                Icons.spa_rounded,
                size: 48,
                color: VivrantColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
