part of '../vivrant_api.dart';

extension VivrantWellnessApi on VivrantApi {
  Future<void> logSleep(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/sleep', data: body);
  }

  Future<Map<String, dynamic>> coachSleep() async {
    final res =
        await _client.post<Map<String, dynamic>>('/api/mobile/sleep/coach');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> addHydration(int ml) async {
    await _client.post('/api/mobile/hydration', data: {'ml': ml});
  }

  Future<void> scheduleHydrationReminders() async {
    await _client.post('/api/mobile/hydration/reminders');
  }

  Future<void> logMood(int mood, {String? note}) async {
    await _client.post('/api/mobile/mindfulness/mood', data: {
      'mood': mood,
      if (note != null) 'note': note,
    });
  }

  Future<Map<String, dynamic>> coachMindfulness() async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/mindfulness/coach',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<JournalEntry>> listJournal() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/journal');
    return (res.data?['entries'] as List? ?? [])
        .map((e) => JournalEntry.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<JournalEntry> saveJournal(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/journal',
      data: body,
    );
    return JournalEntry.fromJson(
      Map<String, dynamic>.from(res.data?['entry'] ?? res.data ?? {}),
    );
  }

  Future<void> deleteJournal(int id) async {
    await _client.delete('/api/mobile/journal/$id');
  }

  Future<Map<String, dynamic>> reflectJournal() async {
    final res =
        await _client.post<Map<String, dynamic>>('/api/mobile/journal/reflect');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Habit>> listHabits() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/habits');
    return (res.data?['habits'] as List? ?? [])
        .map((e) => Habit.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> addHabit(String title) async {
    await _client.post('/api/mobile/habits', data: {'title': title});
  }

  Future<void> toggleHabit(int id, bool done) async {
    await _client.post('/api/mobile/habits/$id/toggle', data: {'done': done});
  }

  Future<void> deleteHabit(int id) async {
    await _client.delete('/api/mobile/habits/$id');
  }

  Future<List<Map<String, dynamic>>> listChallenges() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/habits/challenges',
    );
    return (res.data?['challenges'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> createChallenge(Map<String, dynamic> body) async {
    await _client.post('/api/mobile/habits/challenges', data: body);
  }
}
