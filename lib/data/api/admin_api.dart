part of '../vivrant_api.dart';

extension VivrantAdminApi on VivrantApi {
  Future<Map<String, dynamic>> adminOverview() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/overview',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> adminUsers() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/users',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> adminUpdateUser(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/api/mobile/admin/users/$userId',
      data: body,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> adminTickets() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/tickets',
    );
    return (res.data?['tickets'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> adminUpdateTicket(Map<String, dynamic> body) async {
    await _client.patch('/api/mobile/admin/tickets', data: body);
  }

  Future<List<Map<String, dynamic>>> adminAuditLogs() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/audit',
    );
    return (res.data?['logs'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> adminRoles() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/roles',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> adminSettings() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/settings',
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<Map<String, dynamic>> adminBroadcast(Map<String, dynamic> body) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/mobile/admin/settings',
      data: body,
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<List<Map<String, dynamic>>> adminInquiries() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/inquiries',
    );
    return (res.data?['inquiries'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> adminUpdateInquiry(Map<String, dynamic> body) async {
    await _client.patch('/api/mobile/admin/inquiries', data: body);
  }

  Future<Map<String, dynamic>> adminActivity({
    String memberId = 'all',
    String module = 'all',
  }) async {
    final res = await _client.get<Map<String, dynamic>>(
      '/api/mobile/admin/activity',
      query: {
        'member_id': memberId,
        'module': module,
      },
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }
}
