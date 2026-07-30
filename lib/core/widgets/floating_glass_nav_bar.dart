import 'dart:ui';

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
class FloatingGlassNavBar extends StatelessWidget {
  const FloatingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingNavDestination> destinations;

  static const double barHeight = 64;
  static const double horizontalMargin = 14;
  static const double bottomGap = 8;

  /// Space to reserve above the system inset so content clears the floating bar.
  static double clearanceFor(BuildContext context) {
    return barHeight + bottomGap + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final accentSoft =
        dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final n = destinations.length;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalMargin,
        0,
        horizontalMargin,
        bottomGap + safeBottom,
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
                  height: barHeight,
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 340),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment(
                          n <= 1
                              ? 0
                              : -1 + (2 * selectedIndex / (n - 1)),
                          0,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 1 / n,
                          heightFactor: 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 7,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 340),
                              curve: Curves.easeOutCubic,
                              decoration: BoxDecoration(
                                color: accentSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < n; i++)
                            Expanded(
                              child: _NavItem(
                                destination: destinations[i],
                                selected: i == selectedIndex,
                                accent: accent,
                                muted: muted,
                                ink: ink,
                                onTap: () {
                                  if (i != selectedIndex) {
                                    HapticFeedback.selectionClick();
                                  }
                                  onDestinationSelected(i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.accent,
    required this.muted,
    required this.ink,
    required this.onTap,
  });

  final FloatingNavDestination destination;
  final bool selected;
  final Color accent;
  final Color muted;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : muted;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashColor: accent.withValues(alpha: 0.12),
          highlightColor: accent.withValues(alpha: 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.86, end: 1).animate(
                          animation,
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    key: ValueKey<bool>(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? accent : ink.withValues(alpha: 0.72),
                  height: 1.1,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft fade + slide when switching shell tabs (keeps IndexedStack state).
class TabSwitchTransition extends StatefulWidget {
  const TabSwitchTransition({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<TabSwitchTransition> createState() => _TabSwitchTransitionState();
}

class _TabSwitchTransitionState extends State<TabSwitchTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      value: 1,
    );
    _opacity = const AlwaysStoppedAnimation(1);
    _offset = const AlwaysStoppedAnimation(Offset.zero);
  }

  @override
  void didUpdateWidget(covariant TabSwitchTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;

    _direction = widget.index >= oldWidget.index ? 1 : -1;
    _opacity = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _offset = Tween<Offset>(
      begin: Offset(0.018 * _direction, 0.012),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _offset,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
