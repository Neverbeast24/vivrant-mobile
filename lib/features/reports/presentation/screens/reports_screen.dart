import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

/// Reports directory — weekly numbers and leftovers are separate pages.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.reports);
    if (cached != null) {
      _data = Map<String, dynamic>.from(cached);
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ref.read(vivrantApiProvider).reports();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.reports, data);
      setState(() => _data = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final calories = (_data?['calories'] as num?)?.toInt();
    final steps = (_data?['steps'] as num?)?.toInt();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Reports')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Insights',
              title: 'Weekly',
              highlight: 'overview',
            ),
            Text(
              'Numbers, leftovers, and a weekly story each get their own page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            ...staggerAppear([
              ModuleTile(
                icon: Icons.bar_chart_rounded,
                label: 'This week',
                caption: calories == null
                    ? 'Averages and a weekly summary'
                    : '$calories kcal · ${steps ?? 0} steps / day',
                onTap: () => context.push('/reports/week'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.checklist_outlined,
                label: 'Still open today',
                caption: 'Meals, movement, water, habits',
                onTap: () => context.push('/reports/open'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
