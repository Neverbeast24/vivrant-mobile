import 'package:flutter/material.dart';

/// Generous spacing for mobile. Prefer extra pages over packing a screen.
abstract final class VivrantLayout {
  static const pagePadding = EdgeInsets.fromLTRB(24, 20, 24, 64);
  static const sheetPadding = EdgeInsets.fromLTRB(24, 12, 24, 32);

  static const sectionGap = 28.0;
  static const blockGap = 20.0;
  static const itemGap = 16.0;
  static const tileGap = 16.0;
  static const fieldGap = 18.0;
  static const inlineGap = 12.0;

  static const cardPadding = EdgeInsets.all(22);
  static const rowPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 18);
  static const headerBottom = 28.0;

  static const tileIconSize = 48.0;
  static const minTap = 48.0;
}

/// Vertical space between module tiles / list rows.
class TileGap extends StatelessWidget {
  const TileGap({super.key, this.size = VivrantLayout.tileGap});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}

/// Vertical space between distinct sections on a page.
class SectionGap extends StatelessWidget {
  const SectionGap({super.key, this.size = VivrantLayout.sectionGap});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size);
}
