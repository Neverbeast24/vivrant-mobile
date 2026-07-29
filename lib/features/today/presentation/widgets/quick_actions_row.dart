import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Quick-action chips on the Today home screen.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return VivrantPanel(
      title: 'Quick actions',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ActionChip(
            avatar: const Icon(Icons.restaurant, size: 16),
            label: const Text('Log meal'),
            onPressed: () => context.go('/nutrition/log'),
          ),
          ActionChip(
            avatar: const Icon(Icons.directions_run, size: 16),
            label: const Text('Log workout'),
            onPressed: () => context.go('/move/log'),
          ),
          ActionChip(
            avatar: const Icon(Icons.water_drop, size: 16),
            label: const Text('Add water'),
            onPressed: () => context.push('/hydration'),
          ),
          ActionChip(
            avatar: const Icon(Icons.auto_awesome, size: 16),
            label: const Text('Ask AI'),
            onPressed: () => context.go('/ai'),
          ),
        ],
      ),
    );
  }
}
