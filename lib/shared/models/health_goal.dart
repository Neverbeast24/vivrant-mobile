class HealthGoal {
  HealthGoal({
    required this.id,
    required this.title,
    required this.category,
    this.targetValue,
    this.currentValue,
    this.unit,
    this.targetDate,
    this.status = 'active',
  });

  final int id;
  final String title;
  final String category;
  final double? targetValue;
  final double? currentValue;
  final String? unit;
  final String? targetDate;
  final String status;

  factory HealthGoal.fromJson(Map<String, dynamic> json) => HealthGoal(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? 'other',
        targetValue: (json['target_value'] as num?)?.toDouble(),
        currentValue: (json['current_value'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        targetDate: json['target_date'] as String?,
        status: json['status'] as String? ?? 'active',
      );

  HealthGoal copyWith({
    int? id,
    String? title,
    String? category,
    double? targetValue,
    double? currentValue,
    String? unit,
    String? targetDate,
    String? status,
  }) =>
      HealthGoal(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        targetValue: targetValue ?? this.targetValue,
        currentValue: currentValue ?? this.currentValue,
        unit: unit ?? this.unit,
        targetDate: targetDate ?? this.targetDate,
        status: status ?? this.status,
      );
}
