import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class MovementScreen extends ConsumerStatefulWidget {
  const MovementScreen({super.key});

  @override
  ConsumerState<MovementScreen> createState() => _MovementScreenState();
}

class _MovementScreenState extends ConsumerState<MovementScreen> {
  List<WorkoutLog> _items = [];
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
      final items = await ref.read(vivrantApiProvider).listWorkouts();
      if (!mounted) return;
      setState(() {
        _items = items;
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
    final minutes = _items.fold<int>(0, (s, w) => s + (w.durationMinutes ?? 0));
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            PageHeader(
              eyebrow: 'Movement',
              title: 'Activity',
              highlight: 'pulse',
              trailing: IconButton(
                onPressed: () => context.push('/move/log'),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
            StatCard(
              label: 'Today',
              value: '$minutes min',
              caption: '${_items.length} sessions',
              icon: Icons.directions_run,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (_items.isEmpty)
              EmptyState(
                message: 'No workouts yet.',
                action: ElevatedButton(
                  onPressed: () => context.push('/move/log'),
                  child: const Text('Log workout'),
                ),
              )
            else
              ..._items.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.title,
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${w.activityType} · ${w.durationMinutes ?? '—'} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .deleteWorkout(w.id);
                              _load();
                            } catch (e) {
                              if (!mounted) return;
                              context.showError(apiErrorMessage(e));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final res =
                      await ref.read(vivrantApiProvider).suggestWorkoutAi();
                  if (!mounted) return;
                  context.showInfo(
                    res['suggestion']?.toString() ?? res.toString(),
                  );
                } catch (e) {
                  if (!mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Suggest workout with AI'),
            ),
          ],
        ),
      ),
    );
  }
}
