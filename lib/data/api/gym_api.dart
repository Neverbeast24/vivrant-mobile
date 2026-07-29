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

  Future<Map<String, dynamic>> createAiGymPlan() async {
    final res =
        await _client.post<Map<String, dynamic>>('/api/mobile/gym/plans/ai');
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
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }
}
