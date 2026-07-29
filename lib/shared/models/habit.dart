class Habit {
  Habit({
    required this.id,
    required this.title,
    this.doneToday = false,
  });

  final int id;
  final String title;
  final bool doneToday;

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        doneToday: json['done_today'] as bool? ?? false,
      );

  Habit copyWith({
    int? id,
    String? title,
    bool? doneToday,
  }) =>
      Habit(
        id: id ?? this.id,
        title: title ?? this.title,
        doneToday: doneToday ?? this.doneToday,
      );
}
