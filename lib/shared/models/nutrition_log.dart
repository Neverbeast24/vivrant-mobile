class NutritionLog {
  NutritionLog({
    required this.id,
    required this.mealName,
    required this.mealType,
    this.calories,
    this.proteinG,
    this.carbsG,
    this.fatG,
    required this.loggedAt,
  });

  final int id;
  final String mealName;
  final String mealType;
  final double? calories;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final DateTime loggedAt;

  factory NutritionLog.fromJson(Map<String, dynamic> json) => NutritionLog(
        id: (json['id'] as num).toInt(),
        mealName: json['meal_name'] as String? ?? '',
        mealType: json['meal_type'] as String? ?? 'snack',
        calories: (json['calories'] as num?)?.toDouble(),
        proteinG: (json['protein_g'] as num?)?.toDouble(),
        carbsG: (json['carbs_g'] as num?)?.toDouble(),
        fatG: (json['fat_g'] as num?)?.toDouble(),
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
