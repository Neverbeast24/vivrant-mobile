import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Training directory — activity, programs, and gym each get their own page.
class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Training',
            title: 'Move and',
            highlight: 'train',
          ),
          Text(
            'Pick one destination. Sessions, demos, and programs are not stacked here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SectionGap(),
          ...staggerAppear([
            ModuleTile(
              icon: Icons.add_circle_outline,
              label: 'Log workout',
              caption: 'A walk, gym work, or today’s session',
              onTap: () => context.push('/move/log'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.directions_run,
              label: 'Activity log',
              caption: 'Past workouts and minutes',
              onTap: () => context.push('/move/activity'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Training program',
              caption: 'Saved AI programs',
              onTap: () => context.push('/gym/plans'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.history_rounded,
              label: 'Sessions',
              caption: 'Check off today’s program',
              onTap: () => context.push('/gym/sessions'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.play_circle_outline,
              label: 'Exercise demos',
              caption: 'Form videos',
              onTap: () => context.push('/gym/demos'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Machines',
              caption: 'Equipment guides',
              onTap: () => context.push('/gym/machines'),
            ),
          ]),
        ],
      ),
    );
  }
}
