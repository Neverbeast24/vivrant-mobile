import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../../data/gym_labels.dart';

class TodaysProgramMoves extends StatelessWidget {
  const TodaysProgramMoves({
    super.key,
    required this.plans,
    required this.exercises,
    required this.machinesOnly,
    this.onSelect,
  });

  final List<Map<String, dynamic>> plans;
  final List<GymExercise> exercises;
  final bool machinesOnly;
  final ValueChanged<GymExercise>? onSelect;

  @override
  Widget build(BuildContext context) {
    final plan = plans.isEmpty ? null : plans.first;
    final days = (plan?['days'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final today = pickTodaysPlanDay(days, null, planTrainingDaysList(plan));
    final programmed = (today?['exercises'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final matched = <({String name, GymExercise exercise, String sets})>[];
    for (final ex in programmed) {
      final name = ex['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      final found = findExerciseMatch(name, exercises);
      if (found == null) continue;
      if (machinesOnly ? !found.isMachine : found.isMachine) continue;
      matched.add((
        name: name,
        exercise: found,
        sets: ex['sets']?.toString() ?? '',
      ));
    }
    final unmatched = programmed.where((ex) {
      final name = (ex['name']?.toString() ?? '').toLowerCase();
      return name.isNotEmpty &&
          !matched.any((row) => row.name.toLowerCase() == name);
    }).toList();

    return VivrantPanel(
      title: today == null
          ? 'Today’s program'
          : 'Today · ${today['focus'] ?? 'session'}',
      trailing: TextButton(
        onPressed: () => context.push('/gym/sessions'),
        child: const Text('Start'),
      ),
      child: today != null
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final row in matched)
                  ActionChip(
                    label: Text(
                      row.sets.isEmpty
                          ? row.exercise.name
                          : '${row.exercise.name} · ${row.sets}',
                    ),
                    onPressed: onSelect == null
                        ? null
                        : () => onSelect!(row.exercise),
                  ),
                for (final ex in unmatched)
                  Chip(label: Text(displayGymMoveName(ex['name']?.toString()))),
                if (programmed.isEmpty)
                  const Text('Rest day — browse the library below.'),
              ],
            )
          : TextButton(
              onPressed: () => context.push(plan == null ? '/gym/plans' : '/gym/sessions'),
              child: Text(
                plan == null
                    ? 'Create a program so today’s moves show here'
                    : 'Rest day — nothing programmed today',
              ),
            ),
    );
  }
}
