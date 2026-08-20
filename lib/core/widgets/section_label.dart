import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 2,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: c.brandGradient,
            ),
          ),
          Expanded(
            child: Text(
              text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: c.ink.withValues(alpha: 0.58),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
