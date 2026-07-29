class WorkoutLog {
  WorkoutLog({
    required this.id,
    required this.title,
    required this.activityType,
    this.durationMinutes,
    this.caloriesBurned,
    required this.loggedAt,
  });

  final int id;
  final String title;
  final String activityType;
  final int? durationMinutes;
  final double? caloriesBurned;
  final DateTime loggedAt;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => WorkoutLog(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        activityType: json['activity_type'] as String? ?? 'other',
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
