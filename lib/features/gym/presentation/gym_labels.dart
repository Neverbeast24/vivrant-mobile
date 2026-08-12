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

/// Mirrors web `muscleFilters` for gym catalog filtering.
const gymMuscleFilters = <String>[
  'all',
  'legs',
  'inner_thighs',
  'calves',
  'glutes',
  'hamstrings',
  'chest',
  'back',
  'shoulders',
  'traps',
  'arms',
  'forearms',
  'core',
  'lower_back',
  'full_body',
  'cardio',
  'mobility',
];

/// Short beginner-friendly muscle chips; remaining filters stay behind "More".
const gymMuscleFiltersPrimary = <String>[
  'all',
  'legs',
  'chest',
  'back',
  'arms',
  'core',
];

String muscleFilterLabel(String value) {
  switch (value) {
    case 'all':
      return 'All muscles';
    case 'lower_back':
      return 'Lower back';
    case 'full_body':
      return 'Full body';
    case 'inner_thighs':
      return 'Inner thighs';
    default:
      return humanizeLabel(value);
  }
}

/// Mirrors web `clampGymPlanPrefs` sanitize rules for known catalog slugs.
List<String> sanitizeKnownMachineSlugs(Iterable<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final slug = raw.trim().toLowerCase();
    if (slug.isEmpty || slug.length > 80 || seen.contains(slug)) continue;
    seen.add(slug);
    out.add(slug);
    if (out.length >= 60) break;
  }
  return out;
}

/// Mirrors web sanitize for free-text custom exercises (max 20, ≤80 chars).
List<String> sanitizeCustomExercises(Iterable<String> input) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final name = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length < 2) continue;
    final clipped = name.length > 80 ? name.substring(0, 80) : name;
    final key = clipped.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(clipped);
    if (out.length >= 20) break;
  }
  return out;
}

/// Mirrors web sanitize for avoid targets (allowlist only).
List<String> sanitizeAvoidTargets(Iterable<String> input) {
  final allow = gymAvoidTargets.toSet();
  final seen = <String>{};
  final out = <String>[];
  for (final raw in input) {
    final target = raw.trim().toLowerCase().replaceAll(' ', '_');
    if (!allow.contains(target) || seen.contains(target)) continue;
    seen.add(target);
    out.add(target);
  }
  return out;
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
