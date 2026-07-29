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
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<AiChatMessage>> chatHistory() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/ai/chat');
    return (res.data?['messages'] as List? ?? [])
        .map((e) => AiChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<AiChatMessage> askAi(String question) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/ai/chat',
      data: {'question': question},
    );
    return AiChatMessage.fromJson(
      Map<String, dynamic>.from(res.data?['message'] ?? res.data ?? {}),
    );
  }

  Future<Map<String, dynamic>> generateInsight() async {
    final res =
        await _client.post<Map<String, dynamic>>('/api/mobile/ai/insights');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> listReminders() async {
    final res =
        await _client.get<Map<String, dynamic>>('/api/mobile/ai/reminders');
    return (res.data?['reminders'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createReminder(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/ai/reminders', data: body);
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
