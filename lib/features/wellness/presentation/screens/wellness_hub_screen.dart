import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../widgets/wellness_pulse_bar.dart';

/// Wellness directory — sleep, water, and mood log on their own pages.
class WellnessHubScreen extends ConsumerStatefulWidget {
  const WellnessHubScreen({super.key});

  @override
  ConsumerState<WellnessHubScreen> createState() => _WellnessHubScreenState();
}

class _WellnessHubScreenState extends ConsumerState<WellnessHubScreen> {
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
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Wellness'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Wellness',
              title: 'Body signals,',
              highlight: 'one at a time',
            ),
            Text(
              'Sleep, water, and mood each have a dedicated page.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SkeletonFeed(),
              )
            else if (_error != null)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else ...[
              WellnessPulseBar(today: _today),
              const SectionGap(),
            ],
            ...staggerAppear([
              ModuleTile(
                icon: Icons.nightlight_round,
                label: 'Sleep',
                caption: 'Hours, quality, and coach',
                onTap: () => context.push('/sleep'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.water_drop_outlined,
                label: 'Hydration',
                caption: 'Water log and reminders',
                onTap: () => context.push('/hydration'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.air,
                label: 'Mindfulness',
                caption: 'Mood and calm',
                onTap: () => context.push('/mindfulness'),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
