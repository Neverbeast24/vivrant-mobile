import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class GymOverviewScreen extends ConsumerStatefulWidget {
  const GymOverviewScreen({super.key});

  @override
  ConsumerState<GymOverviewScreen> createState() => _GymOverviewScreenState();
}

class _GymOverviewScreenState extends ConsumerState<GymOverviewScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.gymOverview);
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
      final data = await ref.read(vivrantApiProvider).gymOverview();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymOverview, data);
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

  int _n(String key) => (_data?[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final sessions = _n('sessionCount');
    final minutes = _n('totalMinutes');
    final machines = _n('machineCount');
    final demos = _n('demoCount');
    final plans = _n('planCount');

    return GradientScaffold(
      appBar: AppBar(title: const Text('Gym')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Training',
              title: 'Train with',
              highlight: 'intent',
            ),
            Text(
              'Demos, machines, sessions, and programs each have their own page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            if (_error != null)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else ...[
              StatCard(
                label: 'Sessions',
                value: _loading ? '—' : '$sessions',
                caption: _loading ? 'Loading' : '$minutes min logged',
                icon: Icons.fitness_center_rounded,
              ),
              const SectionGap(),
            ],
            ...staggerAppear([
              ModuleTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'Exercise demos',
                caption: demos > 0 ? '$demos form clips' : 'Free-weight and bodyweight',
                onTap: () => context.push('/gym/demos'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Machines',
                caption: machines > 0
                    ? '$machines guided demos'
                    : 'Equipment walkthroughs',
                onTap: () => context.push('/gym/machines'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.history_rounded,
                label: 'Sessions',
                caption: sessions > 0
                    ? '$sessions logged recently'
                    : 'Today’s program and rest timer',
                onTap: () => context.push('/gym/sessions'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.auto_awesome_rounded,
                label: 'Training program',
                caption: plans > 0
                    ? '$plans saved program${plans == 1 ? '' : 's'}'
                    : 'AI programs and routines',
                onTap: () => context.push('/gym/plans'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
