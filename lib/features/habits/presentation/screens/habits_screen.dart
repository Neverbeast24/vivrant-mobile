import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  List<Habit> _habits = [];
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
      final habits = await ref.read(vivrantApiProvider).listHabits();
      if (!mounted) return;
      setState(() {
        _habits = habits;
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

  Future<void> _add() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New habit'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Habit title'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
      try {
        await ref.read(vivrantApiProvider).addHabit(ctrl.text.trim());
        _load();
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = _habits.where((h) => h.doneToday).length;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            onPressed: () => context.push('/habits/challenges'),
            icon: const Icon(Icons.emoji_events_outlined),
          ),
          IconButton(onPressed: _add, icon: const Icon(Icons.add)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Consistency',
              title: 'Daily',
              highlight: 'habits',
            ),
            StatCard(
              label: 'Today',
              value: '$done / ${_habits.length}',
              caption: 'completed',
              icon: Icons.local_fire_department_outlined,
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
            else if (_habits.isEmpty)
              EmptyState(
                message: 'No habits yet. Add your first.',
                action: ElevatedButton(
                  onPressed: _add,
                  child: const Text('Add habit'),
                ),
              )
            else
              ..._habits.map(
                (h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: Row(
                      children: [
                        Checkbox(
                          value: h.doneToday,
                          onChanged: (v) async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .toggleHabit(h.id, v ?? false);
                              _load();
                            } catch (e) {
                              if (!mounted) return;
                              context.showError(apiErrorMessage(e));
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            h.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: h.doneToday
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .deleteHabit(h.id);
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
          ],
        ),
      ),
    );
  }
}
