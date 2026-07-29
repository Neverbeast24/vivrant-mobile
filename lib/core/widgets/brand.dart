import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/vivrant_colors.dart';

/// Wordmark + mark used across splash, auth, and shell.
class VivrantBrand extends StatelessWidget {
  const VivrantBrand({
    super.key,
    this.compact = false,
    this.dark = false,
  });

  final bool compact;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final ink = dark ? Colors.white : VivrantColors.ink;
    final muted = dark ? Colors.white60 : VivrantColors.muted;

    final mark = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/brand/vivrant-mark.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.spa_rounded,
          color: VivrantColors.accent,
        ),
      ),
    );

    if (compact) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'VIVRΛNT',
              style: GoogleFonts.spaceGrotesk(
                color: ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
              ),
            ),
            Text(
              'LONG LIVE LIFE',
              style: GoogleFonts.spaceGrotesk(
                color: muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
