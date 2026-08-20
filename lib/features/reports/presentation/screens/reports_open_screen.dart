import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class ReportsOpenScreen extends ConsumerStatefulWidget {
  const ReportsOpenScreen({super.key});

  @override
  ConsumerState<ReportsOpenScreen> createState() => _ReportsOpenScreenState();
}

class _ReportsOpenScreenState extends ConsumerState<ReportsOpenScreen> {
  Map<String, dynamic> _today = const {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await ref.read(vivrantApiProvider).getToday();
      if (!mounted) return;
      setState(() {
        _today = today;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = (_today['meals_today'] as num?)?.toInt() ?? 0;
    final workouts = (_today['workouts_today'] as num?)?.toInt() ?? 0;
    final water = (_today['water_ml'] as num?)?.toInt() ?? 0;
    final habitsDone = (_today['habits_done_today'] as num?)?.toInt() ?? 0;
    final habitsTotal = (_today['habits_total'] as num?)?.toInt() ?? 0;
    final groceries = _today['groceries'] is List
        ? (_today['groceries'] as List).length
        : 0;

    final items = <({String label, String detail, String href, IconData icon})>[
      if (meals == 0)
        (
          label: 'Log a meal',
          detail: 'Nothing eaten logged yet',
          href: '/nutrition/log',
          icon: Icons.restaurant_outlined,
        ),
      if (workouts == 0)
        (
          label: 'Move',
          detail: 'No workout or gym session yet',
          href: '/move/log',
          icon: Icons.fitness_center_outlined,
        ),
      if (water < 2400)
        (
          label: 'Water',
          detail: '${2400 - water} ml left of 2400',
          href: '/hydration',
          icon: Icons.water_drop_outlined,
        ),
      if (habitsTotal > 0 && habitsDone < habitsTotal)
        (
          label: 'Habits',
          detail: '${habitsTotal - habitsDone} still open',
          href: '/habits',
          icon: Icons.local_fire_department_outlined,
        ),
      if (groceries > 0)
        (
          label: 'Shopping',
          detail: '$groceries on the list',
          href: '/groceries',
          icon: Icons.shopping_basket_outlined,
        ),
    ];

    return GradientScaffold(
      appBar: AppBar(title: const Text('Still open')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Reports',
              title: 'Still',
              highlight: 'open',
            ),
            Text(
              'One leftover at a time. Each tile opens its own page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (items.isEmpty)
              EmptyState(
                title: 'Caught up',
                message: 'Meals, movement, water, and habits look complete for today.',
                action: OutlinedButton(
                  onPressed: () => context.go('/today'),
                  child: const Text('Back to Today'),
                ),
              )
            else
              ...staggerAppear([
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const TileGap(),
                  ModuleTile(
                    icon: items[i].icon,
                    label: items[i].label,
                    caption: items[i].detail,
                    onTap: () => context.push(items[i].href),
                  ),
                ],
              ]),
          ],
        ),
      ),
    );
  }
}
