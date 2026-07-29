import 'package:equatable/equatable.dart';

class DailyCheckin extends Equatable {
  const DailyCheckin({
    this.energy,
    this.mood,
    this.sleepMinutes,
    this.sleepQuality,
    this.bedtime,
    this.wakeTime,
    this.steps,
    this.waterMl,
    this.note,
  });

  final int? energy;
  final int? mood;
  final int? sleepMinutes;
  final int? sleepQuality;
  final String? bedtime;
  final String? wakeTime;
  final int? steps;
  final int? waterMl;
  final String? note;

  factory DailyCheckin.fromJson(Map<String, dynamic> json) => DailyCheckin(
        energy: (json['energy'] as num?)?.toInt(),
        mood: (json['mood'] as num?)?.toInt(),
        sleepMinutes: (json['sleep_minutes'] as num?)?.toInt(),
        sleepQuality: (json['sleep_quality'] as num?)?.toInt(),
        bedtime: json['bedtime'] as String?,
        wakeTime: json['wake_time'] as String?,
        steps: (json['steps'] as num?)?.toInt(),
        waterMl: (json['water_ml'] as num?)?.toInt(),
        note: json['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (energy != null) 'energy': energy,
        if (mood != null) 'mood': mood,
        if (sleepMinutes != null) 'sleep_minutes': sleepMinutes,
        if (sleepQuality != null) 'sleep_quality': sleepQuality,
        if (bedtime != null) 'bedtime': bedtime,
        if (wakeTime != null) 'wake_time': wakeTime,
        if (steps != null) 'steps': steps,
        if (waterMl != null) 'water_ml': waterMl,
        if (note != null) 'note': note,
      };

  @override
  List<Object?> get props => [energy, mood, steps, waterMl];
}
