import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

/// Soft icon well used next to titles and in list leading slots.
class IconWell extends StatelessWidget {
  const IconWell({
    super.key,
    required this.icon,
    this.size = 48,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.accentSoft,
            Color.lerp(
                  c.accentSoft,
                  c.accent,
                  c.dark ? 0.28 : 0.16,
                ) ??
                c.accentSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.accent.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: c.accent.withValues(alpha: c.dark ? 0.18 : 0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: c.accent, size: iconSize),
    );
  }
}
