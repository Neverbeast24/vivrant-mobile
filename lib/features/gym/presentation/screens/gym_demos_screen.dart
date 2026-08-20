import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../../../../shared/providers/module_cache.dart';
import '../../data/gym_labels.dart';
import '../widgets/exercise_demo_card.dart';
import '../widgets/exercise_demo_sheet.dart';
import '../widgets/todays_program_moves.dart';

class GymDemosScreen extends ConsumerStatefulWidget {
  const GymDemosScreen({super.key});

  @override
  ConsumerState<GymDemosScreen> createState() => _GymDemosScreenState();
}

class _GymDemosScreenState extends ConsumerState<GymDemosScreen> {
  final _query = TextEditingController();
  /// Fresh field name avoids hot-reload keeping an old `List<Map>` in state.
  List<GymExercise> _exercises = const [];
  List<Map<String, dynamic>> _plans = const [];
  bool _loading = true;
  String? _error;
  String _muscle = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<GymExercise>>(ModuleCacheKeys.gymDemos);
    if (cached != null) {
      _exercises = List<GymExercise>.from(cached);
      _loading = false;
    }
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
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.gymDemos);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(vivrantApiProvider);
      final rows = await api.gymExercises();
      List<Map<String, dynamic>> plans = const [];
      try {
        plans = await api.gymPlans();
      } catch (_) {}
      if (!mounted) return;
      final exercises = rows
          .map(GymExercise.fromJson)
          .where((e) => !e.isMachine)
          .toList(growable: false);
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymDemos, exercises);
      setState(() {
        _exercises = exercises;
        _plans = plans;
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
      appBar: AppBar(title: const Text('Exercise demos')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    padding: VivrantLayout.pagePadding,
                    children: [
                      EmptyState(
                        message: _error!,
                        action: OutlinedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: VivrantLayout.pagePadding,
                    children: [
                      const PageHeader(
                        eyebrow: 'Library',
                        title: 'Exercise',
                        highlight: 'demos',
                      ),
                      TodaysProgramMoves(
                        plans: _plans,
                        exercises: _exercises,
                        machinesOnly: false,
                        onSelect: (exercise) =>
                            showExerciseDemoSheet(context, exercise),
                      ),
                      const SectionGap(),
                      VivrantSearchField(
                        controller: _query,
                        hintText: 'Search exercises…',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      VivrantFilterChips<String>(
                        options: [
                          for (final muscle in _muscleOptions)
                            VivrantFilterOption(
                              value: muscle,
                              label: muscleFilterLabel(muscle),
                            ),
                        ],
                        selected: _muscle,
                        onSelected: (v) => setState(() => _muscle = v),
                      ),
                      const SizedBox(height: 18),
                      if (_exercises.isEmpty)
                        const EmptyState(message: 'No exercise demos yet.')
                      else if (filtered.isEmpty)
                        const EmptyState(
                          message:
                              'No demos match these filters. Try All or another search.',
                        )
                      else ...[
                        SectionLabel(
                          '${filtered.length} demo${filtered.length == 1 ? '' : 's'}',
                        ),
                        ...filtered.map(
                          (exercise) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ExerciseDemoCard(
                              exercise: exercise,
                              onTap: () =>
                                  showExerciseDemoSheet(context, exercise),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }
}
