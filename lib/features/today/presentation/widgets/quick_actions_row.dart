import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Shortcuts on the Today home screen — programs and the other modules stay one tap away.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    this.programCaption,
    this.mealsToday = 0,
    this.habitsDone,
    this.habitsTotal,
  });

  final String? programCaption;
  final int mealsToday;
  final int? habitsDone;
  final int? habitsTotal;

  @override
  Widget build(BuildContext context) {
    final habitCaption = habitsTotal != null && habitsTotal! > 0
        ? '${habitsDone ?? 0}/$habitsTotal today'
        : 'Start a streak';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VivrantPanel(
          title: 'Jump in',
          child: Column(
            children: [
              ModuleTile(
                icon: Icons.restaurant_outlined,
                label: 'Nutrition',
                caption: mealsToday > 0
                    ? '$mealsToday meal${mealsToday == 1 ? '' : 's'} today'
                    : 'Log a meal',
                onTap: () => context.go('/nutrition'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.fitness_center,
                label: 'Training',
                caption: 'Activity, demos, and gym',
                onTap: () => context.go('/move'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.auto_awesome_outlined,
                label: 'Program',
                caption: programCaption ?? 'Create an AI weekly plan',
                onTap: () => context.push('/gym/plans'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.favorite_outline,
                label: 'Wellness',
                caption: 'Sleep, water, mood',
                onTap: () => context.push('/wellness'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.kitchen_outlined,
                label: 'Kitchen',
                caption: 'Shopping and pantry',
                onTap: () => context.push('/kitchen'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.local_fire_department_outlined,
                label: 'Habits',
                caption: habitCaption,
                onTap: () => context.push('/habits'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Spending',
                caption: 'Monthly budget',
                onTap: () => context.push('/spending'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.auto_awesome,
                label: 'Ask VIVRΛNT',
                caption: 'Chat coach & reminders',
                onTap: () => context.go('/ai'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        VivrantPanel(
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
        ),
      ],
    );
  }
}
