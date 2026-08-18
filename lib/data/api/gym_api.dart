part of '../vivrant_api.dart';

extension VivrantGymApi on VivrantApi {
  Future<Map<String, dynamic>> gymOverview() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/gym');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> gymExercises({String? equipment}) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/gym/exercises',
      query: {if (equipment != null) 'equipment': equipment},
    );
    return (res.data?['exercises'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<GymSession>> gymSessions() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/gym/sessions');
    return (res.data?['sessions'] as List? ?? [])
        .map((e) => GymSession.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<GymSession> logGymSession(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/gym/sessions',
      data: body,
    );
    return GymSession.fromJson(
      Map<String, dynamic>.from(res.data?['session'] ?? res.data ?? {}),
    );
  }

  Future<void> deleteGymSession(int id) async {
    await _client.delete('/api/mobile/gym/sessions/$id');
  }

  Future<Map<String, dynamic>> createAiGymPlan({
    int? daysPerWeek,
    List<int>? trainingDays,
    int? sessionMinutes,
    String? level,
    List<String>? knownMachineSlugs,
    List<String>? knownCustomExercises,
    List<String>? avoidTargets,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/gym/plans/ai',
      data: {
        if (daysPerWeek != null) 'days_per_week': daysPerWeek,
        if (trainingDays != null && trainingDays.isNotEmpty) 'training_days': trainingDays,
        if (sessionMinutes != null) 'session_minutes': sessionMinutes,
        if (level != null && level.isNotEmpty) 'level': level,
        if (knownMachineSlugs != null && knownMachineSlugs.isNotEmpty)
          'known_machine_slugs': knownMachineSlugs,
        if (knownCustomExercises != null && knownCustomExercises.isNotEmpty)
          'known_custom_exercises': knownCustomExercises,
        if (avoidTargets != null && avoidTargets.isNotEmpty)
          'avoid_targets': avoidTargets,
      },
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> gymPlans() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/gym/plans');
    return (res.data?['plans'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> deleteGymPlan(int id) async {
    await _client.delete('/api/mobile/gym/plans/$id');
  }

  Future<Map<String, dynamic>> recommendMachinesAi() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/gym/machines/recommend',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }
}
