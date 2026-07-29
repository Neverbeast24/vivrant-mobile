part of '../vivrant_api.dart';

extension VivrantProfileApi on VivrantApi {
  Future<Profile> getProfile() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/profile');
    return Profile.fromJson(
      Map<String, dynamic>.from(res.data?['profile'] ?? res.data ?? {}),
    );
  }

  Future<Profile> updateProfile(Map<String, dynamic> body) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/api/mobile/profile',
      data: body,
    );
    return Profile.fromJson(
      Map<String, dynamic>.from(res.data?['profile'] ?? res.data ?? {}),
    );
  }

  Future<List<HealthGoal>> listGoals() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/goals');
    return (res.data?['goals'] as List? ?? [])
        .map((e) => HealthGoal.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addGoal(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/goals', data: body);
  }

  Future<void> updateGoalStatus(int id, String status) async {
    await _client.patch('/api/mobile/goals/$id', data: {'status': status});
  }

  Future<void> deleteGoal(int id) async {
    await _client.delete('/api/mobile/goals/$id');
  }

  Future<List<Map<String, dynamic>>> healthHistory() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/health-history',
    );
    return (res.data?['entries'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> addHealthHistory(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/health-history', data: body);
  }

  Future<void> savePreferences(Map<String, dynamic> body) async {
    await _client.put('/api/mobile/settings/preferences', data: body);
  }

  Future<void> submitSupportTicket(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/support/tickets', data: body);
  }

  Future<List<AppNotification>> listNotifications() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/notifications',
    );
    return (res.data?['notifications'] as List? ?? [])
        .map(
          (e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> markNotificationRead(int id) async {
    await _client.post('/api/mobile/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _client.post('/api/mobile/notifications/read-all');
  }

  Future<Map<String, dynamic>> search(String q) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/search',
      query: {'q': q},
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    await _client.post(
      '/api/device-tokens',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterDeviceToken(String token) async {
    await _client.delete('/api/device-tokens', data: {'token': token});
  }
}
