import 'package:flutter/material.dart';

import '../../../core/utils/humanize.dart';

export '../../../core/utils/humanize.dart' show humanizeLabel;

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
