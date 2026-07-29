import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

/// 1–5 score chips (energy, mood, sleep quality).
class ScorePicker extends StatelessWidget {
  const ScorePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.label,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final int max;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          children: List.generate(max, (i) {
            final n = i + 1;
            final selected = value == n;
            return ChoiceChip(
              label: Text('$n'),
              selected: selected,
              onSelected: (_) => onChanged(n),
              selectedColor: VivrantColors.accentSoft,
              labelStyle: TextStyle(
                color: selected ? VivrantColors.accent : VivrantColors.ink,
                fontWeight: FontWeight.w800,
              ),
            );
          }),
        ),
      ],
    );
  }
}
