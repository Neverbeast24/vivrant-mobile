import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../gym_labels.dart';
import '../widgets/exercise_demo_card.dart';
import '../widgets/exercise_demo_sheet.dart';

class GymMachinesScreen extends ConsumerStatefulWidget {
  const GymMachinesScreen({super.key});

  @override
  ConsumerState<GymMachinesScreen> createState() => _GymMachinesScreenState();
}

class _GymMachinesScreenState extends ConsumerState<GymMachinesScreen> {
  final _query = TextEditingController();
  /// Fresh field name avoids hot-reload keeping an old `List<Map>` in state.
  List<GymExercise> _exercises = const [];
  bool _loading = true;
  String? _error;
  String _muscle = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void reassemble() {
    super.reassemble();
    _exercises = const [];
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref.read(vivrantApiProvider).gymExercises();
      if (!mounted) return;
      setState(() {
        _exercises = rows
            .map(GymExercise.fromJson)
            .where((e) => e.isMachine)
            .toList(growable: false);
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

  List<String> get _muscleOptions {
    final groups = _exercises
        .map((e) => e.muscleGroup)
        .where((g) => g.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['all', ...groups];
  }

  List<GymExercise> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _exercises.where((exercise) {
      if (!matchesMuscleFilter(exercise.muscleGroup, _muscle)) return false;
      if (q.isEmpty) return true;
      return exercise.name.toLowerCase().contains(q) ||
          exercise.muscleGroup.toLowerCase().contains(q) ||
          exercise.equipment.toLowerCase().contains(q) ||
          exercise.difficulty.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Machines')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              eyebrow: 'Equipment',
              title: 'Machine',
              highlight: 'picks',
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final res =
                      await ref.read(vivrantApiProvider).recommendMachinesAi();
                  if (!mounted) return;
                  context.showInfo(
                    res['summary']?.toString() ?? res.toString(),
                  );
                } catch (e) {
                  if (!mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Recommend machines with AI'),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
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
            else if (_exercises.isEmpty)
              const EmptyState(message: 'No machine demos yet.')
            else ...[
              TextField(
                controller: _query,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: VivrantColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Search machines…',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: VivrantColors.ink.withValues(alpha: 0.45),
                  ),
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _query.clear();
                            setState(() {});
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: VivrantColors.ink.withValues(alpha: 0.45),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _muscleOptions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      FilterChip(
                        label: Text(muscleFilterLabel(_muscleOptions[i])),
                        selected: _muscle == _muscleOptions[i],
                        showCheckmark: false,
                        onSelected: (_) =>
                            setState(() => _muscle = _muscleOptions[i]),
                        selectedColor: VivrantColors.accentSoft,
                        backgroundColor: VivrantColors.panel,
                        side: BorderSide(
                          color: _muscle == _muscleOptions[i]
                              ? VivrantColors.accent.withValues(alpha: 0.35)
                              : VivrantColors.ink.withValues(alpha: 0.1),
                        ),
                        labelStyle: TextStyle(
                          color: _muscle == _muscleOptions[i]
                              ? VivrantColors.accentDeep
                              : VivrantColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No machines match these filters. Try All or another search.',
                )
              else ...[
                SectionLabel(
                  '${filtered.length} machine${filtered.length == 1 ? '' : 's'}',
                ),
                ...filtered.map(
                  (exercise) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExerciseDemoCard(
                      exercise: exercise,
                      onTap: () => showExerciseDemoSheet(context, exercise),
                    ),
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
