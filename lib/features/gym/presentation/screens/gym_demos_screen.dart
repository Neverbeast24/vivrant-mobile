import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../gym_labels.dart';
import '../widgets/exercise_demo_card.dart';
import '../widgets/exercise_demo_sheet.dart';

class GymDemosScreen extends ConsumerStatefulWidget {
  const GymDemosScreen({super.key});

  @override
  ConsumerState<GymDemosScreen> createState() => _GymDemosScreenState();
}

class _GymDemosScreenState extends ConsumerState<GymDemosScreen> {
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
            .where((e) => !e.isMachine)
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
                    padding: const EdgeInsets.all(20),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      const PageHeader(
                        eyebrow: 'Library',
                        title: 'Exercise',
                        highlight: 'demos',
                      ),
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
                          hintText: 'Search exercises…',
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
                                    color: VivrantColors.ink
                                        .withValues(alpha: 0.45),
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
                              _MuscleChip(
                                label: muscleFilterLabel(_muscleOptions[i]),
                                selected: _muscle == _muscleOptions[i],
                                onTap: () => setState(
                                  () => _muscle = _muscleOptions[i],
                                ),
                              ),
                            ],
                          ],
                        ),
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

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: VivrantColors.accentSoft,
      backgroundColor: VivrantColors.panel,
      side: BorderSide(
        color: selected
            ? VivrantColors.accent.withValues(alpha: 0.35)
            : VivrantColors.ink.withValues(alpha: 0.1),
      ),
      labelStyle: TextStyle(
        color: selected ? VivrantColors.accentDeep : VivrantColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}
