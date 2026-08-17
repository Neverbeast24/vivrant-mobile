import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Combined daily activity + gym entry point (mirrors web Training hub).
class TrainingHubScreen extends StatelessWidget {
  const TrainingHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const PageHeader(
            eyebrow: 'Training',
            title: 'Move and',
            highlight: 'train',
          ),
          Text(
            'Track daily activity, log a workout, or open the gym.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ModuleTile(
            icon: Icons.directions_walk_outlined,
            label: 'Daily activity',
            caption: 'Steps, walks, and suggestions',
            onTap: () => context.push('/move/activity'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.add_circle_outline,
            label: 'Log workout',
            caption: 'Walk, run, yoga, light strength',
            onTap: () => context.push('/move/log'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.auto_awesome_outlined,
            label: 'Training program',
            caption: 'Saved AI programs and today’s session',
            onTap: () => context.push('/gym/plans'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.play_circle_outline,
            label: 'Exercise demos',
            caption: 'Form videos for free weights and bodyweight',
            onTap: () => context.push('/gym/demos'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Machines',
            caption: 'Equipment guides and AI picks',
            onTap: () => context.push('/gym/machines'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.history_rounded,
            label: 'Sessions',
            caption: 'Log gym work and review history',
            onTap: () => context.push('/gym/sessions'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.fitness_center,
            label: 'Gym overview',
            caption: 'Videos, machines, workouts, and programs',
            onTap: () => context.push('/gym'),
          ),
        ],
      ),
    );
  }
}
