import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/module_cache.dart';
import '../widgets/quick_actions_row.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.today);
    if (cached != null) {
      _data = cached;
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
      final data = await ref.read(vivrantApiProvider).getToday();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.today, data);
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

  Future<void> _quickCheckin() async {
    final energy = await _pickScore('Energy (1–5)');
    if (energy == null || !mounted) return;
    final mood = await _pickScore('Mood (1–5)');
    if (mood == null || !mounted) return;
    try {
      await ref.read(vivrantApiProvider).saveCheckin(
            DailyCheckin(energy: energy, mood: mood),
          );
      if (!mounted) return;
      context.showSuccess('Check-in saved');
      _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  Future<int?> _pickScore(String title) async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              Wrap(
                spacing: 8,
                children: List.generate(5, (i) {
                  final n = i + 1;
                  return ActionChip(
                    label: Text('$n'),
                    onPressed: () => Navigator.pop(context, n),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final profile = ref.watch(authProvider).profile;
    final checkin = _data?['checkin'] as Map?;
    final calories = (_data?['calories'] as num?)?.toInt() ?? 0;
    final steps = (_data?['steps'] as num?)?.toInt() ??
        (checkin?['steps'] as num?)?.toInt() ??
        0;
    final water = (_data?['water_ml'] as num?)?.toInt() ??
        (checkin?['water_ml'] as num?)?.toInt() ??
        0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        color: c.accent,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                const Expanded(child: VivrantBrand()),
                IconButton(
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                IconButton(
                  onPressed: () => context.push('/profile'),
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: c.accentSoft,
                    backgroundImage: profile?.avatarUrl != null
                        ? NetworkImage(profile!.avatarUrl!)
                        : null,
                    child: profile?.avatarUrl == null
                        ? Text(
                            (profile?.displayName.isNotEmpty == true
                                    ? profile!.displayName[0]
                                    : 'V')
                                .toUpperCase(),
                            style: TextStyle(
                              color: c.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PageHeader(
              eyebrow: 'Today',
              title: 'Hello,',
              highlight: profile?.displayName.split(' ').first ?? 'friend',
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
                      caption: 'logged today',
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Steps',
                      value: '$steps',
                      caption: 'of ${profile?.dailyStepGoal ?? 8000}',
                      icon: Icons.directions_walk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              StatCard(
                label: 'Water',
                value: '$water ml',
                caption: 'goal ${profile?.dailyWaterGoalMl ?? 2500} ml',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 18),
              VivrantPanel(
                title: 'Quick check-in',
                trailing: TextButton(
                  onPressed: _quickCheckin,
                  child: const Text('Log'),
                ),
                child: Text(
                  checkin == null
                      ? 'How is your energy and mood today?'
                      : 'Energy ${checkin['energy'] ?? '—'} · Mood ${checkin['mood'] ?? '—'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 18),
              const QuickActionsRow(),
            ],
          ],
        ),
      ),
    );
  }
}
