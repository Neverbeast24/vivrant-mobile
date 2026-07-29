import 'package:flutter/material.dart';

import '../../../../core/theme/vivrant_colors.dart';

/// Compact protein / carbs / fat chips for a meal.
class MacroChips extends StatelessWidget {
  const MacroChips({
    super.key,
    this.proteinG,
    this.carbsG,
    this.fatG,
  });

  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (proteinG != null) _chip('P ${proteinG!.toStringAsFixed(0)}g'),
      if (carbsG != null) _chip('C ${carbsG!.toStringAsFixed(0)}g'),
      if (fatG != null) _chip('F ${fatG!.toStringAsFixed(0)}g'),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: VivrantColors.accentSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: VivrantColors.accent,
        ),
      ),
    );
  }
}
