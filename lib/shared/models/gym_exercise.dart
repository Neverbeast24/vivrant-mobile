class GymExercise {
  const GymExercise({
    required this.id,
    required this.slug,
    required this.name,
    required this.muscleGroup,
    required this.equipment,
    required this.difficulty,
    this.durationSeconds = 0,
    this.demoVideoUrl,
    this.demoThumbnailUrl,
    this.cues,
  });

  final int id;
  final String slug;
  final String name;
  final String muscleGroup;
  final String equipment;
  final String difficulty;
  final int durationSeconds;
  final String? demoVideoUrl;
  final String? demoThumbnailUrl;
  final String? cues;

  bool get isMachine =>
      equipment == 'machine' ||
      equipment == 'cable' ||
      equipment == 'cardio_machine';

  bool get hasDemo =>
      demoVideoUrl != null && demoVideoUrl!.trim().isNotEmpty;

  factory GymExercise.fromJson(Map<String, dynamic> json) {
    return GymExercise(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Exercise',
      muscleGroup: json['muscle_group']?.toString() ?? '',
      equipment: json['equipment']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      demoVideoUrl: json['demo_video_url']?.toString(),
      demoThumbnailUrl: json['demo_thumbnail_url']?.toString(),
      cues: json['cues']?.toString(),
    );
  }
}
