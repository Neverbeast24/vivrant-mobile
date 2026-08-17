import 'package:flutter/material.dart';

import '../../../core/utils/humanize.dart';
import '../../../shared/models/gym_exercise.dart';

export '../../../core/utils/humanize.dart' show humanizeLabel;

/// Mirrors web `GYM_PLAN_LEVELS` for AI gym plan prefs.
const gymPlanLevels = <String>['beginner', 'intermediate', 'advanced'];

String sanitizeGymPlanLevel(String? input) {
  final value = (input ?? '').trim().toLowerCase();
  if (value == 'intermediate' || value == 'advanced') return value;
  return 'beginner';
}

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
  'glutes',
  'chest',
  'back',
  'shoulders',
  'arms',
  'core',
  'cardio',
];

/// Mirrors web `MAX_KNOWN_MACHINE_SLUGS`.
const maxKnownMachineSlugs = 250;

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
    if (out.length >= maxKnownMachineSlugs) break;
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

List<String> programRecommendations(Map<String, dynamic> plan) {
  final top = plan['recommendations'];
  if (top is List) {
    return top
        .map((e) => e.toString().trim())
        .where((e) => e.length >= 2)
        .take(8)
        .toList();
  }
  final days = plan['days'];
  if (days is List && days.isNotEmpty && days.first is Map) {
    final recs = Map<String, dynamic>.from(days.first as Map)['recommendations'];
    if (recs is List) {
      return recs
          .map((e) => e.toString().trim())
          .where((e) => e.length >= 2)
          .take(8)
          .toList();
    }
  }
  return const [];
}

String formatGymExerciseLine(Map<String, dynamic> ex) {
  final name = ex['name']?.toString() ?? 'Movement';
  final sets = ex['sets']?.toString() ?? '';
  final rest = ex['rest']?.toString() ?? '';
  final weight = ex['weight']?.toString().trim() ?? '';
  final parts = <String>[
    name,
    if (sets.isNotEmpty) sets,
    if (weight.isNotEmpty) weight,
    if (rest.isNotEmpty) 'rest $rest',
  ];
  return parts.join(' · ');
}

List<Map<String, String>> dayAlternatives(Map<String, dynamic> day) {
  final raw = day['alternatives'];
  if (raw is! List) return const [];
  final out = <Map<String, String>>[];
  final seen = <String>{};
  for (final item in raw) {
    var insteadOf = '';
    var use = '';
    if (item is String) {
      final text = item.trim();
      final instead = RegExp(r'^(.+?)\s+instead of\s+(.+)$', caseSensitive: false)
          .firstMatch(text);
      final arrow = RegExp(r'^(.+?)\s*(?:→|->)\s*(.+)$').firstMatch(text);
      if (instead != null) {
        use = instead.group(1)!.trim();
        insteadOf = instead.group(2)!.trim();
      } else if (arrow != null) {
        insteadOf = arrow.group(1)!.trim();
        use = arrow.group(2)!.trim();
      }
    } else if (item is Map) {
      final row = Map<String, dynamic>.from(item);
      insteadOf = (row['instead_of'] ?? row['from'] ?? '').toString().trim();
      use = (row['use'] ?? row['to'] ?? row['name'] ?? '').toString().trim();
    }
    if (insteadOf.length < 2 || use.length < 2) continue;
    final key = '${insteadOf.toLowerCase()}=>${use.toLowerCase()}';
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add({'instead_of': insteadOf, 'use': use});
    if (out.length >= 4) break;
  }
  return out;
}

List<Map<String, String>> dayAdditionals(Map<String, dynamic> day) {
  final raw = day['additionals'];
  if (raw is! List) return const [];
  final out = <Map<String, String>>[];
  final seen = <String>{};
  for (final item in raw) {
    var name = '';
    var sets = '';
    if (item is String) {
      name = item.trim();
    } else if (item is Map) {
      final row = Map<String, dynamic>.from(item);
      name = (row['name'] ?? row['use'] ?? '').toString().trim();
      sets = (row['sets'] ?? '').toString().trim();
    }
    if (name.length < 2) continue;
    final key = name.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add({
      'name': name,
      if (sets.isNotEmpty) 'sets': sets,
    });
    if (out.length >= 4) break;
  }
  return out;
}

const _addonComplement = <String, List<String>>{
  'back': ['shoulders', 'arms', 'core'],
  'chest': ['arms', 'shoulders', 'core'],
  'shoulders': ['arms', 'core'],
  'traps': ['back', 'shoulders'],
  'arms': ['shoulders', 'core'],
  'forearms': ['arms'],
  'legs': ['calves', 'hamstrings', 'core', 'inner_thighs'],
  'hamstrings': ['calves', 'core', 'legs'],
  'inner_thighs': ['calves', 'core', 'legs'],
  'glutes': ['hamstrings', 'core'],
  'calves': ['core', 'legs'],
  'core': ['cardio'],
  'cardio': ['core', 'mobility'],
  'lower_back': ['core', 'hamstrings'],
  'full_body': ['core', 'cardio'],
  'mobility': ['core'],
};

String _addonSets(GymExercise item) {
  if (item.equipment == 'cardio_machine' || item.muscleGroup == 'cardio') {
    return '8–12 mins easy';
  }
  if (item.muscleGroup == 'core' || item.muscleGroup == 'mobility') {
    return '2 x 12-15';
  }
  return '2–3 x 12-15';
}

List<Map<String, dynamic>> enrichPlanDays(
  List<Map<String, dynamic>> days,
  List<GymExercise> catalog,
) {
  if (days.isEmpty || catalog.isEmpty) return days;
  return [
    for (final day in days) _enrichPlanDay(Map<String, dynamic>.from(day), catalog),
  ];
}

Map<String, dynamic> _enrichPlanDay(
  Map<String, dynamic> day,
  List<GymExercise> catalog,
) {
  final used = <String>{};
  for (final raw in (day['exercises'] as List? ?? const [])) {
    if (raw is Map) {
      final name = (raw['name'] ?? '').toString().toLowerCase();
      if (name.isNotEmpty) used.add(name);
    }
  }
  final alternatives = dayAlternatives(day);
  final additionals = dayAdditionals(day);
  for (final swap in alternatives) {
    used.add((swap['use'] ?? '').toLowerCase());
  }
  for (final addon in additionals) {
    used.add((addon['name'] ?? '').toLowerCase());
  }

  final exercises = (day['exercises'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  for (final ex in exercises) {
    if (alternatives.length >= 3) break;
    final name = ex['name']?.toString() ?? '';
    final match = findExerciseMatch(name, catalog);
    if (match == null) continue;
    final pool = catalog.where((item) {
      final key = item.name.toLowerCase();
      return item.muscleGroup == match.muscleGroup &&
          key != match.name.toLowerCase() &&
          !used.contains(key);
    }).toList();
    final swapped = pool.where((item) => item.equipment != match.equipment).toList();
    final pick = swapped.isNotEmpty ? swapped.first : (pool.isNotEmpty ? pool.first : null);
    if (pick == null) continue;
    used.add(pick.name.toLowerCase());
    alternatives.add({'instead_of': name, 'use': pick.name});
  }

  final dayMuscles = <String>[];
  for (final ex in exercises) {
    final match = findExerciseMatch(ex['name']?.toString() ?? '', catalog);
    if (match != null && !dayMuscles.contains(match.muscleGroup)) {
      dayMuscles.add(match.muscleGroup);
    }
  }
  final targets = <String>[];
  for (final muscle in dayMuscles) {
    for (final next in _addonComplement[muscle] ?? const <String>[]) {
      if (!targets.contains(next)) targets.add(next);
    }
  }
  for (final muscle in targets) {
    if (additionals.length >= 2) break;
    GymExercise? pick;
    for (final item in catalog) {
      if (item.muscleGroup == muscle && !used.contains(item.name.toLowerCase())) {
        pick = item;
        break;
      }
    }
    if (pick == null) continue;
    used.add(pick.name.toLowerCase());
    additionals.add({'name': pick.name, 'sets': _addonSets(pick)});
  }

  return {
    ...day,
    if (alternatives.isNotEmpty) 'alternatives': alternatives,
    if (additionals.isNotEmpty) 'additionals': additionals,
  };
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

const _weekdayFull = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];
const _weekdayShort = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

/// Pick the session that should show on Today — weekday name first, else Mon-based rotation.
/// Mirrors viva-server `pickTodaysPlanDay`.
Map<String, dynamic>? pickTodaysPlanDay(
  List<Map<String, dynamic>> days, [
  DateTime? date,
]) {
  if (days.isEmpty) return null;
  final now = date ?? DateTime.now();
  final full = _weekdayFull[now.weekday - 1];
  final short = _weekdayShort[now.weekday - 1];
  for (final day in days) {
    final label = (day['day']?.toString() ?? '').toLowerCase();
    final tokens = label.split(RegExp(r'[\s,/:.-]+')).where((part) => part.isNotEmpty);
    if (label.contains(full) || tokens.contains(short)) return day;
  }
  final mondayIndex = now.weekday == DateTime.sunday ? 6 : now.weekday - 1;
  return days[mondayIndex % days.length];
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
