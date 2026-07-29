import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  int _added = 0;
  bool _busy = false;

  Future<void> _add(int ml) async {
    setState(() => _busy = true);
    try {
      await ref.read(vivrantApiProvider).addHydration(ml);
      if (!mounted) return;
      setState(() => _added += ml);
      context.showSuccess('Added $ml ml');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _schedule() async {
    try {
      await ref.read(vivrantApiProvider).scheduleHydrationReminders();
      if (!mounted) return;
      context.showSuccess('Hydration reminders scheduled');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Hydration')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            eyebrow: 'Water',
            title: 'Stay',
            highlight: 'hydrated',
          ),
          StatCard(
            label: 'This session',
            value: '$_added ml',
            caption: 'logged from this screen',
            icon: Icons.water_drop_outlined,
          ),
          const SizedBox(height: 18),
          VivrantPanel(
            title: 'Quick add',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ml in [150, 250, 350, 500])
                  ActionChip(
                    label: Text('$ml ml'),
                    onPressed: _busy ? null : () => _add(ml),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _schedule,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Schedule reminders'),
          ),
        ],
      ),
    );
  }
}
