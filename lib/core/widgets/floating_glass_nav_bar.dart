import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/vivrant_colors.dart';

class FloatingNavDestination {
  const FloatingNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Instagram-style floating frosted-glass bottom navigation.
///
/// A single pill physically slides under the finger. Slots grow/shrink with
/// proximity, and the selected label fades in. Pass [positionListenable]
/// from [VivrantSlidingIndexedStack] so the pill tracks a page swipe at 60fps.
class FloatingGlassNavBar extends StatefulWidget {
  const FloatingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.selectedPosition,
    this.positionListenable,
    this.onDragSettled,
    this.enableHaptics = true,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;

  /// Fractional page position while swiping (e.g. 1.35). Ignored when
  /// [positionListenable] is set.
  final double? selectedPosition;

  /// Live fractional index from the page swipe — rebuilds only this nav.
  final ValueListenable<double>? positionListenable;

  /// Called when a footer drag settles. Defaults to [onDestinationSelected].
  final ValueChanged<int>? onDragSettled;

  final bool enableHaptics;

  static const double barHeight = 64;
  static const double horizontalMargin = 14;
  static const double bottomGap = 8;
  static const double _selectedExtraWeight = 1.8;
  static const Duration _animDuration = Duration(milliseconds: 350);
  static const Curve _animCurve = Curves.easeOutCubic;
  static const double _dragSlop = 18;
  static const double _iconSize = 22;

  /// Space to reserve above the system inset so content clears the floating bar.
  static double clearanceFor(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.paddingOf(context).bottom;
  }

  @override
  State<FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<FloatingGlassNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _visualPosition = 0;

  double _dragStartX = 0;
  double _grabOffsetX = 0;
  bool _footerDragActive = false;

  @override
  void initState() {
    super.initState();
    _visualPosition =
        widget.positionListenable?.value ??
        widget.selectedPosition ??
        widget.selectedIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: FloatingGlassNavBar._animDuration,
    );
    _animation = AlwaysStoppedAnimation<double>(_visualPosition);
    _controller.addListener(_onAnimTick);
  }

  void _onAnimTick() {
    _visualPosition = _animation.value;
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onAnimTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FloatingGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.positionListenable != null) {
      _controller.stop();
      return;
    }

    final live = widget.selectedPosition;
    if (live != null) {
      _controller.stop();
      _visualPosition = live;
      return;
    }

    final target = widget.selectedIndex
        .clamp(0, math.max(0, widget.destinations.length - 1))
        .toDouble();
    if ((target - _visualPosition).abs() < 0.001) {
      _controller.stop();
      _visualPosition = target;
      return;
    }

    _animatePillTo(target);
  }

  void _animatePillTo(double target) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (reduceMotion) {
      _controller.stop();
      _visualPosition = target;
      return;
    }

    _animation = Tween<double>(begin: _visualPosition, end: target).animate(
      CurvedAnimation(
        parent: _controller,
        curve: FloatingGlassNavBar._animCurve,
      ),
    );
    _controller.forward(from: 0);
  }

  void _handleTap(int index) {
    if (widget.enableHaptics &&
        !kIsWeb &&
        MediaQuery.maybeOf(context)?.disableAnimations != true) {
      HapticFeedback.selectionClick();
    }
    widget.onDestinationSelected(index);
  }

  ValueNotifier<double>? get _mutablePosition {
    final listenable = widget.positionListenable;
    return listenable is ValueNotifier<double> ? listenable : null;
  }

  void _startFooterDrag(
    double currentPosition,
    double localX,
    double totalWidth,
  ) {
    if (_mutablePosition == null || totalWidth <= 0) return;
    _dragStartX = localX;
    _grabOffsetX =
        localX - _computeLayout(currentPosition, totalWidth).pillCenter;
    _footerDragActive = false;
  }

  void _updateFooterDrag(double localX, double totalWidth) {
    final notifier = _mutablePosition;
    if (notifier == null || totalWidth <= 0) return;
    if (!_footerDragActive) {
      if ((localX - _dragStartX).abs() < FloatingGlassNavBar._dragSlop) return;
      _footerDragActive = true;
    }
    final targetCenter = localX - _grabOffsetX;
    notifier.value = _positionForPillCenter(targetCenter, totalWidth);
  }

  /// Invert [pillCenter] → fractional tab index. Layout is monotonic in
  /// position, so a short binary search keeps the pill under the finger.
  double _positionForPillCenter(double targetCenter, double totalWidth) {
    final maxIndex = (widget.destinations.length - 1).toDouble();
    if (maxIndex <= 0) return 0;
    var lo = 0.0;
    var hi = maxIndex;
    for (var i = 0; i < 20; i++) {
      final mid = (lo + hi) / 2;
      final center = _computeLayout(mid, totalWidth).pillCenter;
      if (center < targetCenter) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return ((lo + hi) / 2).clamp(0.0, maxIndex);
  }

  _PillTrackLayout _computeLayout(double position, double totalWidth) {
    final count = widget.destinations.length;
    final clamped = position.clamp(0.0, math.max(0, count - 1).toDouble());
    final proximities = List<double>.generate(count, (i) {
      return math.max(0.0, 1.0 - (i - clamped).abs());
    });
    final weights = [
      for (final p in proximities)
        1.0 + FloatingGlassNavBar._selectedExtraWeight * p,
    ];
    final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);
    final widths = [
      for (final w in weights) totalWidth * w / math.max(totalWeight, 0.001),
    ];
    final lefts = List<double>.filled(count, 0);
    for (var i = 1; i < count; i++) {
      lefts[i] = lefts[i - 1] + widths[i - 1];
    }

    final last = math.max(0, count - 1);
    final i0 = clamped.floor().clamp(0, last).toInt();
    final i1 = clamped.ceil().clamp(0, last).toInt();
    final frac = clamped - i0;
    return _PillTrackLayout(
      lefts: lefts,
      widths: widths,
      proximities: proximities,
      pillLeft: lerpDouble(lefts[i0], lefts[i1], frac)!,
      pillWidth: lerpDouble(widths[i0], widths[i1], frac)!,
    );
  }

  void _finishFooterDrag() {
    final notifier = _mutablePosition;
    if (notifier == null || !_footerDragActive) return;
    _footerDragActive = false;
    final target = notifier.value.round().clamp(
      0,
      widget.destinations.length - 1,
    );
    if (widget.enableHaptics &&
        !kIsWeb &&
        MediaQuery.maybeOf(context)?.disableAnimations != true) {
      HapticFeedback.selectionClick();
    }
    (widget.onDragSettled ?? widget.onDestinationSelected)(target);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.destinations.isEmpty) return const SizedBox.shrink();

    final listenable = widget.positionListenable;
    if (listenable != null) {
      return ValueListenableBuilder<double>(
        valueListenable: listenable,
        builder: (context, live, _) {
          _visualPosition = live;
          return _buildBar(context, position: live);
        },
      );
    }

    final live = widget.selectedPosition;
    final position = live ?? _visualPosition;
    return _buildBar(context, position: position);
  }

  Widget _buildBar(BuildContext context, {required double position}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final accentSoft = dark
        ? VivrantColors.darkAccentSoft
        : VivrantColors.accentSoft;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final clamped = position.clamp(
      0.0,
      (widget.destinations.length - 1).toDouble(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        FloatingGlassNavBar.horizontalMargin,
        0,
        FloatingGlassNavBar.horizontalMargin,
        FloatingGlassNavBar.bottomGap + safeBottom,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
              blurRadius: 28,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: ColoredBox(
              color: dark
                  ? const Color(0xCC1C2620)
                  : Colors.white.withValues(alpha: 0.78),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white.withValues(alpha: 0.90),
                  ),
                ),
                child: SizedBox(
                  height: FloatingGlassNavBar.barHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _buildTrack(
                          position: clamped,
                          totalWidth: constraints.maxWidth,
                          accent: accent,
                          accentSoft: accentSoft,
                          muted: muted,
                          ink: ink,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrack({
    required double position,
    required double totalWidth,
    required Color accent,
    required Color accentSoft,
    required Color muted,
    required Color ink,
  }) {
    final count = widget.destinations.length;
    final layout = _computeLayout(position, totalWidth);
    final labelStyle = GoogleFonts.spaceGrotesk(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      height: 1.1,
      color: accent,
    );

    int indexAt(double dx) {
      final x = dx.clamp(0.0, totalWidth);
      for (var i = 0; i < count; i++) {
        if (x <= layout.lefts[i] + layout.widths[i]) return i;
      }
      return count - 1;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _handleTap(indexAt(details.localPosition.dx)),
      onHorizontalDragStart: (details) =>
          _startFooterDrag(position, details.localPosition.dx, totalWidth),
      onHorizontalDragUpdate: (details) =>
          _updateFooterDrag(details.localPosition.dx, totalWidth),
      onHorizontalDragEnd: (_) => _finishFooterDrag(),
      onHorizontalDragCancel: _finishFooterDrag,
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: layout.pillLeft + 3,
              width: math.max(0, layout.pillWidth - 6),
              top: 7,
              bottom: 7,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            for (var i = 0; i < count; i++)
              Positioned(
                left: layout.lefts[i],
                width: layout.widths[i],
                top: 0,
                bottom: 0,
                child: _buildSlot(
                  destination: widget.destinations[i],
                  proximity: layout.proximities[i],
                  accent: accent,
                  muted: muted,
                  ink: ink,
                  labelStyle: labelStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlot({
    required FloatingNavDestination destination,
    required double proximity,
    required Color accent,
    required Color muted,
    required Color ink,
    required TextStyle labelStyle,
  }) {
    final reveal = ((proximity - 0.6) / 0.4).clamp(0.0, 1.0);
    final selected = proximity >= 0.5;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.94 + 0.06 * proximity,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: FloatingGlassNavBar._iconSize,
                    color: Color.lerp(muted, accent, proximity),
                  ),
                ),
                if (reveal > 0)
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: reveal,
                      child: Opacity(
                        opacity: reveal,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            softWrap: false,
                            style: labelStyle.copyWith(
                              color: Color.lerp(ink, accent, proximity),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillTrackLayout {
  const _PillTrackLayout({
    required this.lefts,
    required this.widths,
    required this.proximities,
    required this.pillLeft,
    required this.pillWidth,
  });

  final List<double> lefts;
  final List<double> widths;
  final List<double> proximities;
  final double pillLeft;
  final double pillWidth;

  double get pillCenter => pillLeft + pillWidth / 2;
}
