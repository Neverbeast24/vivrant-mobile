import 'package:flutter/material.dart';

import '../../../core/utils/humanize.dart';
import '../../../shared/models/gym_exercise.dart';

export '../../../core/utils/humanize.dart' show humanizeLabel;

/// Mirrors web `GYM_AVOID_TARGETS` for AI gym plan prefs.
const gymAvoidTargets = <String>[
  'core',
  'arms',
  'forearms',
  'shoulders',
  'chest',
  'back',
  'traps',
  'legs',
  'glutes',
  'hamstrings',
  'calves',
  'inner_thighs',
  'lower_back',
  'cardio',
  'mobility',
];

String muscleFilterLabel(String value) {
  if (value == 'all') return 'All';
  return humanizeLabel(value);
}

const legsMuscleGroups = {'legs', 'hamstrings', 'calves', 'inner_thighs'};

bool matchesMuscleFilter(String muscleGroup, String filter) {
  if (filter == 'all') return true;
  if (filter == 'legs') return legsMuscleGroups.contains(muscleGroup);
  return muscleGroup == filter;
}

/// Match an AI/plan exercise name to a catalog demo (exact, then loose contains).
GymExercise? findExerciseMatch(String name, List<GymExercise> exercises) {
  final needle = name.toLowerCase().trim();
  if (needle.isEmpty) return null;
  for (final item in exercises) {
    if (item.name.toLowerCase() == needle) return item;
  }
  for (final item in exercises) {
    final catalog = item.name.toLowerCase();
    if (needle.contains(catalog) || catalog.contains(needle)) return item;
  }
  final stripped = needle
      .replaceAll(RegExp(r'\b(machine|trainer|bike|climber)\b'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (stripped.isEmpty || stripped == needle) return null;
  for (final item in exercises) {
    final catalog = item.name.toLowerCase();
    final catalogStripped = catalog
        .replaceAll(RegExp(r'\b(machine|trainer)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (catalog.contains(stripped) || stripped.contains(catalogStripped)) {
      return item;
    }
  }
  return null;
}

IconData muscleIcon(String muscleGroup) {
  switch (muscleGroup) {
    case 'core':
      return Icons.accessibility_new_rounded;
    case 'cardio':
      return Icons.directions_run_rounded;
    case 'mobility':
      return Icons.self_improvement_rounded;
    case 'shoulders':
    case 'traps':
      return Icons.sports_gymnastics_rounded;
    case 'back':
    case 'lower_back':
      return Icons.airline_seat_recline_normal_rounded;
    case 'chest':
      return Icons.fitness_center_rounded;
    case 'arms':
    case 'forearms':
      return Icons.back_hand_outlined;
    case 'legs':
    case 'hamstrings':
    case 'calves':
    case 'inner_thighs':
    case 'glutes':
      return Icons.directions_walk_rounded;
    case 'full_body':
      return Icons.person_outline_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

Color difficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'beginner':
      return const Color(0xFF0E7C66);
    case 'intermediate':
      return const Color(0xFFB45309);
    case 'advanced':
      return const Color(0xFFB42318);
    default:
      return const Color(0xFF4A5C54);
  }
}
