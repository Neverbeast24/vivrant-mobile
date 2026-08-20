import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

/// Training-program directory — builder and saved list are separate pages.
class GymPlansHubScreen extends ConsumerStatefulWidget {
  const GymPlansHubScreen({super.key});

  @override
  ConsumerState<GymPlansHubScreen> createState() => _GymPlansHubScreenState();
}

class _GymPlansHubScreenState extends ConsumerState<GymPlansHubScreen> {
  int _planCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.gymPlans);
    if (cached != null) {
      _planCount = cached.length;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final plans = await ref.read(vivrantApiProvider).gymPlans();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymPlans, plans);
      setState(() {
        _planCount = plans.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Training program')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Gym',
              title: 'Training',
              highlight: 'program',
            ),
            Text(
              'Create a week of workouts on one page. Review saved programs on another.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            ...staggerAppear([
              ModuleTile(
                icon: Icons.auto_awesome_outlined,
                label: 'Create a program',
                caption: 'Days, minutes, and AI workouts',
                onTap: () => context.push('/gym/plans/build'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.folder_outlined,
                label: 'Saved programs',
                caption: _loading
                    ? 'Your routines'
                    : _planCount == 0
                        ? 'Nothing saved yet'
                        : '$_planCount saved',
                onTap: () => context.push('/gym/plans/saved'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
