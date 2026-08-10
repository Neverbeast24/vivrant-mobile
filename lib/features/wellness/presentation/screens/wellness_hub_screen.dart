import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';

/// Sleep + hydration + mindfulness entry (mirrors web Wellness hub).
class WellnessHubScreen extends StatelessWidget {
  const WellnessHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Wellness'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const PageHeader(
            eyebrow: 'Wellness',
            title: 'Body signals,',
            highlight: 'one place',
          ),
          Text(
            'Sleep, water, and mood — all from your daily check-in.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ModuleTile(
            icon: Icons.nightlight_round,
            label: 'Sleep',
            caption: 'Rest & recovery',
            onTap: () => context.push('/sleep'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.water_drop_outlined,
            label: 'Hydration',
            caption: 'Water goals',
            onTap: () => context.push('/hydration'),
          ),
          const SizedBox(height: 10),
          ModuleTile(
            icon: Icons.air,
            label: 'Mindfulness',
            caption: 'Mood & calm',
            onTap: () => context.push('/mindfulness'),
          ),
        ],
      ),
    );
  }
}
