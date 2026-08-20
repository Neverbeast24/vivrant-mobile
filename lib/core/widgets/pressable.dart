import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/vivrant_motion.dart';

/// Scales a tappable child down slightly and fires a light haptic.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
    this.haptic = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return AnimatedScale(
      scale: _pressed && enabled ? widget.scale : 1,
      duration: VivrantMotion.fast,
      curve: Curves.easeOutCubic,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap == null
              ? null
              : () {
                  if (widget.haptic) HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          onLongPress: widget.onLongPress,
          onHighlightChanged: enabled ? _setPressed : null,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(20),
          child: widget.child,
        ),
      ),
    );
  }
}
