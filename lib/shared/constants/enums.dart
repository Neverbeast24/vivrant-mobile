/// Shared form option lists used by log / add screens.

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
  'groceries',
  'supplements',
  'fitness',
  'medical',
  'other',
];

const List<String> pantryCategories = [
  'produce',
  'dairy',
  'protein',
  'grains',
  'other',
];

String labelForOption(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1)}';
}
