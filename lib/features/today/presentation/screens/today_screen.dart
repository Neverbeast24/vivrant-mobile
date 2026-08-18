import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/humanize.dart';
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
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => context.push('/profile'),
                  icon: CircleAvatar(
                    radius: 16,
                    backgroundColor: c.accentSoft,
                    backgroundImage: profile?.avatarUrl != null
                        ? CachedNetworkImageProvider(profile!.avatarUrl!)
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
              _TodayProgramCard(program: _data?['program']),
              const SizedBox(height: 18),
              _TodayDoNow(
                habits: (_data?['habits'] as List? ?? const [])
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
                groceries: (_data?['groceries'] as List? ?? const [])
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList(),
                waterMl: water,
                calories: calories,
                onChanged: _load,
              ),
              const SizedBox(height: 18),
              QuickActionsRow(
                programCaption: _programCaption(_data?['program']),
                mealsToday: (_data?['meals_today'] as num?)?.toInt() ?? 0,
                habitsDone: (_data?['habits_done_today'] as num?)?.toInt(),
                habitsTotal: (_data?['habits_total'] as num?)?.toInt(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String? _programCaption(Object? raw) {
  if (raw is! Map) return null;
  final plan = Map<String, dynamic>.from(raw);
  final title = plan['title']?.toString().trim();
  if (title == null || title.isEmpty) return null;
  final count = (plan['planCount'] as num?)?.toInt() ?? 1;
  if (count > 1) return '$title · $count saved';
  return title;
}

class _TodayProgramCard extends StatelessWidget {
  const _TodayProgramCard({required this.program});

  final Object? program;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final raw = program;
    final plan = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final today = plan?['today'] is Map
        ? Map<String, dynamic>.from(plan!['today'] as Map)
        : null;
    final exercises = (today?['exercises'] as List?)
            ?.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        const <Map<String, dynamic>>[];

    return VivrantPanel(
      title: 'Training program',
      trailing: TextButton(
        onPressed: () => context.push(plan == null ? '/gym/plans' : '/gym/sessions'),
        child: Text(plan == null ? 'Create' : 'Start'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (plan == null)
            Text(
              'No program yet. Create a weekly plan and it will show up here every day.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            Text(
              plan['title']?.toString() ?? 'Your program',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if ((plan['focus']?.toString() ?? '').isNotEmpty)
                  humanizeLabel(plan['focus'].toString()),
                if (plan['daysPerWeek'] != null) '${plan['daysPerWeek']} days/week',
                if ((plan['planCount'] as num?)?.toInt() != null &&
                    (plan['planCount'] as num).toInt() > 1)
                  '${plan['planCount']} saved',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.ink.withValues(alpha: 0.62),
                  ),
            ),
            if (today != null) ...[
              const SizedBox(height: 12),
              Text(
                'Today · ${today['day'] ?? ''} · ${humanizeLabel(today['focus']?.toString() ?? '')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
              const SizedBox(height: 6),
              for (final ex in exercises.take(4))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    [
                      ex['name']?.toString() ?? '',
                      if ((ex['sets']?.toString() ?? '').isNotEmpty) ex['sets'],
                    ].where((part) => (part ?? '').toString().isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

class _TodayDoNow extends ConsumerWidget {
  const _TodayDoNow({
    required this.habits,
    required this.groceries,
    required this.waterMl,
    required this.calories,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> groceries;
  final int waterMl;
  final int calories;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        VivrantPanel(
          title: 'Habits today',
          trailing: TextButton(
            onPressed: () => context.push('/habits'),
            child: const Text('All'),
          ),
          child: habits.isEmpty
              ? const Text('Add a habit so it shows up here each morning.')
              : Column(
                  children: [
                    for (final habit in habits)
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(habit['title']?.toString() ?? 'Habit'),
                        value: habit['done_today'] == true,
                        onChanged: (v) async {
                          try {
                            await ref.read(vivrantApiProvider).toggleHabit(
                                  (habit['id'] as num).toInt(),
                                  v ?? false,
                                );
                            await onChanged();
                          } catch (e) {
                            if (context.mounted) {
                              context.showError(apiErrorMessage(e));
                            }
                          }
                        },
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        VivrantPanel(
          title: 'Water · $waterMl ml · $calories kcal today',
          trailing: TextButton(
            onPressed: () => context.push('/nutrition/log'),
            child: const Text('Meal'),
          ),
          child: Wrap(
            spacing: 8,
            children: [
              for (final ml in [250, 500])
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(vivrantApiProvider).addHydration(ml);
                      if (context.mounted) context.showSuccess('+$ml ml');
                      await onChanged();
                    } catch (e) {
                      if (context.mounted) {
                        context.showError(apiErrorMessage(e));
                      }
                    }
                  },
                  child: Text('+$ml ml'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        VivrantPanel(
          title: 'Shopping',
          trailing: TextButton(
            onPressed: () => context.push('/groceries'),
            child: const Text('List'),
          ),
          child: groceries.isEmpty
              ? const Text('Shopping list is clear.')
              : Column(
                  children: [
                    for (final item in groceries.take(6))
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item['name']?.toString() ?? 'Item'),
                        subtitle: item['quantity'] == null
                            ? null
                            : Text(item['quantity'].toString()),
                        value: false,
                        onChanged: (_) async {
                          try {
                            await ref.read(vivrantApiProvider).toggleGrocery(
                                  (item['id'] as num).toInt(),
                                  true,
                                );
                            if (context.mounted) {
                              context.showSuccess('Checked · pantry restocked');
                            }
                            await onChanged();
                          } catch (e) {
                            if (context.mounted) {
                              context.showError(apiErrorMessage(e));
                            }
                          }
                        },
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

