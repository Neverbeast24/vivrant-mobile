import 'package:flutter/material.dart';

import '../theme/vivrant_colors.dart';
import '../theme/vivrant_layout.dart';
import '../theme/vivrant_motion.dart';

/// Soft bordered row used in lists (meals, workouts, groceries, …).
class ListRow extends StatefulWidget {
  const ListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final tappable = widget.onTap != null || widget.onLongPress != null;
    return AnimatedScale(
      scale: _pressed && tappable ? 0.985 : 1,
      duration: VivrantMotion.fast,
      curve: Curves.easeOutCubic,
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged:
              tappable ? (value) => setState(() => _pressed = value) : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: VivrantLayout.minTap),
            padding: VivrantLayout.rowPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.ink.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1.3,
                          color: c.ink,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
