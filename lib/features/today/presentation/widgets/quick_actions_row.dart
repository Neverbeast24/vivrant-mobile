import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Shortcuts on Today — destinations only, one tile each.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    this.programCaption,
    this.mealsToday = 0,
  });

  final String? programCaption;
  final int mealsToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Jump in'),
        ...staggerAppear(
          [
            ModuleTile(
              icon: Icons.restaurant_outlined,
              label: 'Nutrition',
              caption: mealsToday > 0
                  ? '$mealsToday meal${mealsToday == 1 ? '' : 's'} today'
                  : 'Log a meal',
              onTap: () => context.go('/nutrition'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.fitness_center,
              label: 'Training',
              caption: programCaption ?? 'Activity, demos, and gym',
              onTap: () => context.go('/move'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.favorite_outline,
              label: 'Wellness',
              caption: 'Sleep, water, mood',
              onTap: () => context.push('/wellness'),
            ),
          ],
          startMs: 80,
        ),
      ],
    );
  }
}
