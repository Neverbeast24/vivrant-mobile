part of '../vivrant_api.dart';

extension VivrantAiApi on VivrantApi {
  Future<Map<String, dynamic>> reports() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/reports');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> weeklyStory() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/reports/weekly-story',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<AiChatMessage>> chatHistory() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/ai/chat',
      options: ApiClient.aiOptions,
    );
    return (res.data?['messages'] as List? ?? [])
        .map((e) => AiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AiChatMessage> askAi(String question) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/chat',
      data: {'question': question},
      options: ApiClient.aiOptions,
    );
    return AiChatMessage.fromJson(
      Map<String, dynamic>.from(res.data?['message'] ?? res.data ?? {}),
    );
  }

  Future<List<Map<String, dynamic>>> listInsights() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/ai/insights');
    return (res.data?['insights'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> generateInsight() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/insights',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> listReminders() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/ai/reminders');
    return (res.data?['reminders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/reminders',
      data: body,
    );
    return Map<String, dynamic>.from(
      res.data?['reminder'] as Map? ?? res.data ?? {},
    );
  }

  /// Draft + save an AI reminder personalized with BMI context.
  Future<Map<String, dynamic>> draftReminderAi() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/reminders/draft',
      options: ApiClient.aiOptions,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  /// Create/refresh reminders from the member's latest active gym plan.
  Future<Map<String, dynamic>> syncRemindersFromGymPlan() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/reminders/sync-gym-plan',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  /// Create/refresh an evening reminder from today’s unfinished items.
  Future<Map<String, dynamic>> syncRemindersFromTodayLeftovers() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/reminders/sync-today',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> toggleReminder(int id, bool enabled) async {
    await _client.patch(
      '/api/mobile/ai/reminders/$id',
      data: {'enabled': enabled},
    );
  }

  Future<void> deleteReminder(int id) async {
    await _client.delete('/api/mobile/ai/reminders/$id');
  }
}
