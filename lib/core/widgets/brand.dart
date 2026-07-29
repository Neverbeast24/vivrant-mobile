import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/vivrant_colors.dart';

/// Wordmark + mark used across splash, auth, and shell.
class VivrantBrand extends StatelessWidget {
  const VivrantBrand({
    super.key,
    this.compact = false,
    this.dark,
  });

  final bool compact;

  /// When null, follows [Theme] brightness.
  final bool? dark;

  @override
  Widget build(BuildContext context) {
    final isDark = dark ?? Theme.of(context).brightness == Brightness.dark;
    final c = VivrantColors.forBrightness(
      isDark ? Brightness.dark : Brightness.light,
    );
    final ink = isDark ? Colors.white : c.ink;
    final muted = isDark ? Colors.white60 : c.muted;

    final mark = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? Colors.white : Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/brand/vivrant-mark.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.spa_rounded,
          color: c.accent,
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
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
              ),
            ),
            Text(
              'LONG LIVE LIFE',
              style: GoogleFonts.spaceGrotesk(
                color: muted,
                fontSize: 10.5,
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
