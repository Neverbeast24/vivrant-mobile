import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_motion.dart';

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
    final c = VivrantColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(max, (i) {
            final n = i + 1;
            final selected = value == n;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(n);
              },
              child: AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: VivrantMotion.fast,
                curve: VivrantMotion.spring,
                child: AnimatedContainer(
                  duration: VivrantMotion.base,
                  curve: VivrantMotion.enter,
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? c.accentSoft : c.panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? c.accent.withValues(alpha: 0.4)
                          : c.ink.withValues(alpha: 0.12),
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: c.accent.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    '$n',
                    style: TextStyle(
                      color: selected ? c.accentDeep : c.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
