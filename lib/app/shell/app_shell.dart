import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../shared/providers/shell_tab_provider.dart';

/// Bottom-nav shell: Today · Nutrition · Training · Ask · More.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _destinations = [
    FloatingNavDestination(
      icon: Icons.wb_sunny_outlined,
      selectedIcon: Icons.wb_sunny_rounded,
      label: 'Today',
    ),
    FloatingNavDestination(
      icon: Icons.restaurant_outlined,
      selectedIcon: Icons.restaurant_rounded,
      label: 'Nutrition',
    ),
    FloatingNavDestination(
      icon: Icons.fitness_center_outlined,
      selectedIcon: Icons.fitness_center_rounded,
      label: 'Training',
    ),
    FloatingNavDestination(
      icon: Icons.auto_awesome_outlined,
      selectedIcon: Icons.auto_awesome,
      label: 'Ask',
    ),
    FloatingNavDestination(
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
      label: 'More',
    ),
  ];

  void _syncTabIndex(int index) {
    if (ref.read(shellTabIndexProvider) != index) {
      ref.read(shellTabIndexProvider.notifier).state = index;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTabIndex(widget.navigationShell.currentIndex);
    });
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTabIndex(widget.navigationShell.currentIndex);
    });
  }

  void _onTap(int index) {
    _syncTabIndex(index);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onDragSettled(int index) {
    _syncTabIndex(index);
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final media = MediaQuery.of(context);
    final clearance = FloatingGlassNavBar.clearanceFor(context);
    final position = ref.read(shellTabPositionProvider);

    return GradientScaffold(
      extendBody: true,
      bottomNavigationBar: FloatingGlassNavBar(
        selectedIndex: index,
        positionListenable: position,
        onDestinationSelected: _onTap,
        onDragSettled: _onDragSettled,
        destinations: _destinations,
      ),
      child: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(bottom: clearance),
        ),
        child: widget.navigationShell,
      ),
    );
  }
}

/// Keeps go_router branch navigators in a swipeable page view that shares
/// position with the footer pill.
class ShellSwipeContainer extends ConsumerWidget {
  const ShellSwipeContainer({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VivrantSlidingIndexedStack(
      index: navigationShell.currentIndex,
      onIndexChanged: (index) => navigationShell.goBranch(index),
      positionNotifier: ref.read(shellTabPositionProvider),
      children: children,
    );
  }
}
