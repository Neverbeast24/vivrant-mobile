part of '../vivrant_api.dart';

extension VivrantAuthApi on VivrantApi {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    final data = Map<String, dynamic>.from(res.data ?? {});
    final access = data['access_token'] as String? ??
        data['session']?['access_token'] as String?;
    final refresh = data['refresh_token'] as String? ??
        data['session']?['refresh_token'] as String?;
    if (access != null) {
      await _client.saveTokens(accessToken: access, refreshToken: refresh);
    }
    return data;
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/api/auth/signup',
      data: {
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      },
    );
    return Map<String, dynamic>.from(res.data ?? {});
  }

  Future<void> forgotPassword(String email) async {
    await _client.post('/api/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword(String password) async {
    await _client.post('/api/auth/reset-password', data: {'password': password});
  }

  Future<void> logout() async {
    try {
      await _client.post('/api/mobile/auth/logout');
    } finally {
      await _client.clearTokens();
    }
  }
}
