class GymSession {
  GymSession({
    required this.id,
    required this.title,
    this.focus,
    this.durationMinutes,
    this.caloriesBurned,
    this.exercises = const [],
    this.notes,
    this.loggedAt,
  });

  final int id;
  final String title;
  final String? focus;
  final int? durationMinutes;
  final double? caloriesBurned;
  final List<Map<String, dynamic>> exercises;
  final String? notes;
  final DateTime? loggedAt;

  factory GymSession.fromJson(Map<String, dynamic> json) => GymSession(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        focus: json['focus'] as String?,
        durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
        caloriesBurned: (json['calories_burned'] as num?)?.toDouble(),
        exercises: (json['exercises'] as List?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        loggedAt: DateTime.tryParse(json['logged_at'] as String? ?? ''),
      );
}
