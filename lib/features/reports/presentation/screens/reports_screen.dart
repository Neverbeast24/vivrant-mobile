import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/share_export.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<String, dynamic>? _data;
  Map<String, dynamic> _today = const {};
  bool _loading = true;
  String? _error;
  String? _story;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.reports);
    if (cached != null) {
      _data = Map<String, dynamic>.from(cached);
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final showSpinner = _data == null;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(vivrantApiProvider);
      final results = await Future.wait<Map<String, dynamic>>([
        api.reports(),
        api.getToday(),
      ]);
      if (!mounted) return;
      final data = results[0];
      final today = results[1];
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.reports, data);
      setState(() {
        _data = data;
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

  Future<void> _weeklyStory() async {
    try {
      final res = await ref.read(vivrantApiProvider).weeklyStory();
      if (!mounted) return;
      setState(() {
        _story = formatAiResponse(
          res,
          keys: const ['story', 'summary', 'insight'],
        );
      });
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final calories = (_data?['calories'] as num?)?.toInt() ?? 0;
    final steps = (_data?['steps'] as num?)?.toInt() ?? 0;
    final workouts = (_data?['workouts'] as num?)?.toInt() ?? 0;
    final water = (_data?['water_ml'] as num?)?.toInt() ?? 0;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (_data != null)
            ShareExportButton(doc: reportsDoc(_data!, story: _story)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Insights',
              title: 'Weekly',
              highlight: 'overview',
            ),
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
            else ...[
              if (_today.isNotEmpty)
                _ReportsCatchUp(today: _today),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Calories',
                      value: '$calories',
                      caption: 'avg / day',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Steps',
                      value: '$steps',
                      caption: 'avg / day',
                      icon: Icons.directions_walk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Workouts',
                      value: '$workouts',
                      caption: 'this week',
                      icon: Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Water',
                      value: '$water ml',
                      caption: 'avg / day',
                      icon: Icons.water_drop_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: _weeklyStory,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate weekly summary'),
              ),
              if (_story != null) ...[
                const SizedBox(height: 16),
                VivrantPanel(
                  title: 'Your week',
                  child: Text(
                    _story!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportsCatchUp extends StatelessWidget {
  const _ReportsCatchUp({required this.today});

  final Map<String, dynamic> today;

  @override
  Widget build(BuildContext context) {
    final meals = (today['meals_today'] as num?)?.toInt() ?? 0;
    final workouts = (today['workouts_today'] as num?)?.toInt() ?? 0;
    final water = (today['water_ml'] as num?)?.toInt() ?? 0;
    final habitsDone = (today['habits_done_today'] as num?)?.toInt() ?? 0;
    final habitsTotal = (today['habits_total'] as num?)?.toInt() ?? 0;
    final groceries = today['groceries'] is List
        ? (today['groceries'] as List).length
        : 0;

    final items = <({String label, String detail, String href})>[
      if (meals == 0)
        (
          label: 'Log a meal',
          detail: 'Nothing eaten logged yet',
          href: '/nutrition/log',
        ),
      if (workouts == 0)
        (
          label: 'Move',
          detail: 'No workout or gym session yet',
          href: '/move/log',
        ),
      if (water < 2400)
        (
          label: 'Water',
          detail: '${2400 - water} ml left of 2400',
          href: '/hydration',
        ),
      if (habitsTotal > 0 && habitsDone < habitsTotal)
        (
          label: 'Habits',
          detail: '${habitsTotal - habitsDone} still open',
          href: '/habits',
        ),
      if (groceries > 0)
        (
          label: 'Shopping',
          detail: '$groceries on the list',
          href: '/groceries',
        ),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: VivrantPanel(
        title: 'Still open today',
        trailing: TextButton(
          onPressed: () => context.go('/today'),
          child: const Text('Today'),
        ),
        child: Column(
          children: [
            for (final item in items)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  item.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(item.detail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(item.href),
              ),
          ],
        ),
      ),
    );
  }
}
