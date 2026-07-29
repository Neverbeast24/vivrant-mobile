import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _story;

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
      final data = await ref.read(vivrantApiProvider).reports();
      if (!mounted) return;
      setState(() {
        _data = data;
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
        _story = res['story']?.toString() ??
            res['summary']?.toString() ??
            res.toString();
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
      appBar: AppBar(title: const Text('Reports')),
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
                label: const Text('Generate weekly story'),
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
