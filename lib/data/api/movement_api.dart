part of '../vivrant_api.dart';

extension VivrantMovementApi on VivrantApi {
  Future<List<WorkoutLog>> listWorkouts({String? date}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/movement/workouts',
      query: {if (date != null) 'date': date},
    );
    final list = res.data?['workouts'] as List? ?? [];
    return list
        .map((e) => WorkoutLog.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<WorkoutLog> logWorkout(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/movement/workouts',
      data: body,
    );
    return WorkoutLog.fromJson(
      Map<String, dynamic>.from(res.data?['workout'] ?? res.data ?? {}),
    );
  }

  Future<void> deleteWorkout(int id) async {
    await _client.delete('/api/mobile/movement/workouts/$id');
  }

  Future<WorkoutLog> updateWorkout(int id, Map<String, dynamic> body) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/api/mobile/movement/workouts/$id',
      data: body,
    );
    return WorkoutLog.fromJson(
      Map<String, dynamic>.from(res.data?['workout'] ?? res.data ?? {}),
    );
  }

  Future<Map<String, dynamic>> suggestWorkoutAi() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/movement/suggest',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }
}
