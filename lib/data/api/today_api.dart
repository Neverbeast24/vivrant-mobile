part of '../vivrant_api.dart';

/// Today home payload (check-in, stats, leftovers).
extension VivrantTodayApi on VivrantApi {
  Future<Map<String, dynamic>> getToday() async {
    final res = await _client.get<Map<String, dynamic>>('/api/mobile/today');
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> saveCheckin(DailyCheckin checkin) async {
    await _client.post('/api/mobile/today/checkin', data: checkin.toJson());
  }
}
