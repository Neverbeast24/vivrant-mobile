import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../shared/providers/shell_tab_provider.dart';

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
    // Defer — writing providers during the route rebuild (e.g. right after
    // login) can throw and abort auth via StateNotifierListenerError.
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

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;
    final media = MediaQuery.of(context);
    final clearance = FloatingGlassNavBar.clearanceFor(context);

    return GradientScaffold(
      extendBody: true,
      bottomNavigationBar: FloatingGlassNavBar(
        selectedIndex: index,
        onDestinationSelected: _onTap,
        destinations: _destinations,
      ),
      child: MediaQuery(
        data: media.copyWith(
          padding: media.padding.copyWith(bottom: clearance),
        ),
        child: TabSwitchTransition(
          index: index,
          child: widget.navigationShell,
        ),
      ),
    );
  }
}
