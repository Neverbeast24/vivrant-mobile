import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

/// Soft icon well used next to titles and in list leading slots.
class IconWell extends StatelessWidget {
  const IconWell({
    super.key,
    required this.icon,
    this.size = 40,
    this.iconSize = 20,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VivrantColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: VivrantColors.accent, size: iconSize),
    );
  }
}
