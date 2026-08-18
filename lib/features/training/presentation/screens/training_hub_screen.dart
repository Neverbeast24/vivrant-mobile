import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';
import '../../../gym/presentation/widgets/program_session_panel.dart';

/// Combined daily activity + gym entry point (mirrors web Training hub).
class TrainingHubScreen extends ConsumerStatefulWidget {
  const TrainingHubScreen({super.key});

  @override
  ConsumerState<TrainingHubScreen> createState() => _TrainingHubScreenState();
}

class _TrainingHubScreenState extends ConsumerState<TrainingHubScreen> {
  List<Map<String, dynamic>> _plans = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.gymPlans);
    if (cached != null) {
      _plans = List<Map<String, dynamic>>.from(cached);
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
        _plans = plans;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const PageHeader(
              eyebrow: 'Training',
              title: 'Move and',
              highlight: 'train',
            ),
            Text(
              'Check off today’s program here, or log a walk.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ProgramSessionPanel(plans: _plans, onLogged: () { _load(); }),
            const SizedBox(height: 16),
            ModuleTile(
              icon: Icons.add_circle_outline,
              label: 'Log workout',
              caption: 'Today’s program, a walk, or gym work',
              onTap: () => context.push('/move/log'),
            ),
            const SizedBox(height: 10),
            ModuleTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Training program',
              caption: 'Saved AI programs and today’s session',
              onTap: () => context.push('/gym/plans'),
            ),
            const SizedBox(height: 10),
            ModuleTile(
              icon: Icons.play_circle_outline,
              label: 'Exercise demos',
              caption: 'Form videos for free weights and bodyweight',
              onTap: () => context.push('/gym/demos'),
            ),
            const SizedBox(height: 10),
            ModuleTile(
              icon: Icons.precision_manufacturing_outlined,
              label: 'Machines',
              caption: 'Equipment guides and AI picks',
              onTap: () => context.push('/gym/machines'),
            ),
            const SizedBox(height: 10),
            ModuleTile(
              icon: Icons.history_rounded,
              label: 'Sessions',
              caption: 'Check off today’s program + rest timer',
              onTap: () => context.push('/gym/sessions'),
            ),
          ],
        ),
      ),
    );
  }
}
