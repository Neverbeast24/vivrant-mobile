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
  int _todayMl = 0;
  int _added = 0;
  bool _busy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    try {
      final today = await ref.read(vivrantApiProvider).getToday();
      if (!mounted) return;
      setState(() {
        _todayMl = (today['water_ml'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _add(int ml) async {
    setState(() => _busy = true);
    try {
      final res = await ref.read(vivrantApiProvider).addHydration(ml);
      if (!mounted) return;
      final serverTotal = (res['water_ml'] as num?)?.toInt();
      setState(() {
        _added += ml;
        _todayMl = serverTotal ?? (_todayMl + ml);
      });
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
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            StatCard(
              label: 'Today',
              value: '$_todayMl ml',
              caption: _added > 0
                  ? '+$_added ml this session'
                  : 'total logged today',
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
        ],
      ),
    );
  }
}
