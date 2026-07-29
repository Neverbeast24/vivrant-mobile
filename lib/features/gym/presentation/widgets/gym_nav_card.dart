import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/vivrant_colors.dart';

/// Destination tile on the gym overview hub.
class GymNavCard extends StatefulWidget {
  const GymNavCard({
    super.key,
    required this.icon,
    required this.label,
    required this.caption,
    required this.path,
    this.featured = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final String path;
  final bool featured;

  @override
  State<GymNavCard> createState() => _GymNavCardState();
}

class _GymNavCardState extends State<GymNavCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    final bg = widget.featured
        ? null
        : (dark ? VivrantColors.darkPanel : Colors.white)
            .withValues(alpha: dark ? 0.92 : 0.96);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            context.push(widget.path);
          },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: widget.featured
                  ? (dark
                      ? VivrantColors.darkBrandGradient
                      : VivrantColors.brandGradient)
                  : null,
              color: bg,
              border: widget.featured
                  ? null
                  : Border.all(color: ink.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: widget.featured
                        ? (dark ? 0.28 : 0.18)
                        : (dark ? 0.08 : 0.05),
                  ),
                  blurRadius: widget.featured ? 22 : 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.featured
                          ? Colors.white.withValues(alpha: 0.18)
                          : soft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: widget.featured ? Colors.white : accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.2,
                      color: widget.featured ? Colors.white : ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                      color: widget.featured
                          ? Colors.white.withValues(alpha: 0.82)
                          : muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
