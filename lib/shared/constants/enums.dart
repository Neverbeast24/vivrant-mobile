/// Shared form option lists used by log / add screens.
library;

const List<String> mealTypes = [
  'breakfast',
  'lunch',
  'dinner',
  'snack',
];

const List<String> activityTypes = [
  'walk',
  'run',
  'strength',
  'cycle',
  'yoga',
  'other',
];

const List<String> expenseCategories = [
  'food',
  'fitness',
  'supplements',
  'wellness',
  'other',
];

const List<String> pantryCategories = [
  'vegetables',
  'fruits',
  'protein',
  'dairy',
  'grains',
  'snacks',
  'drinks',
  'condiments',
  'frozen',
  'other',
];

String labelForOption(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

String normalizeExpenseCategory(String raw) {
  final value = raw.trim().toLowerCase();
  if (expenseCategories.contains(value)) return value;
  if (value == 'groceries' || value == 'grocery') return 'food';
  if (value == 'medical' || value == 'health') return 'wellness';
  return 'other';
}
