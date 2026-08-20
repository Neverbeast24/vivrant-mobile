import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/share_export.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class ReportsWeekScreen extends ConsumerStatefulWidget {
  const ReportsWeekScreen({super.key});

  @override
  ConsumerState<ReportsWeekScreen> createState() => _ReportsWeekScreenState();
}

class _ReportsWeekScreenState extends ConsumerState<ReportsWeekScreen> {
  Map<String, dynamic>? _data;
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
      final data = await ref.read(vivrantApiProvider).reports();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.reports, data);
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
        title: const Text('This week'),
        actions: [
          if (_data != null)
            ShareExportButton(doc: reportsDoc(_data!, story: _story)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Reports',
              title: 'This',
              highlight: 'week',
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
              StatCard(
                label: 'Calories',
                value: '$calories',
                caption: 'avg / day',
                icon: Icons.local_fire_department_outlined,
              ),
              const TileGap(),
              StatCard(
                label: 'Steps',
                value: '$steps',
                caption: 'avg / day',
                icon: Icons.directions_walk,
              ),
              const TileGap(),
              StatCard(
                label: 'Workouts',
                value: '$workouts',
                caption: 'this week',
                icon: Icons.fitness_center,
              ),
              const TileGap(),
              StatCard(
                label: 'Water',
                value: '$water ml',
                caption: 'avg / day',
                icon: Icons.water_drop_outlined,
              ),
              const SectionGap(),
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
