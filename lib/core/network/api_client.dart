import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/env.dart';

const _tokenKey = 'vivrant_access_token';
const _refreshKey = 'vivrant_refresh_token';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});

/// HTTP client for the VIVRΛNT Web mobile REST API.
class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (kDebugMode) {
      debugPrint('[vivrant:api] baseUrl=${Env.apiBaseUrl}');
    }

    // Auth first so debug logs see the real Authorization header.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _resolveAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Only clear the token that actually failed — never wipe a newer
          // session saved by a concurrent login (bootstrap 401 race).
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            final isCredentialAttempt = path.contains('/api/auth/login') ||
                path.contains('/api/auth/signup');
            if (!isCredentialAttempt) {
              final header =
                  error.requestOptions.headers['Authorization']?.toString();
              if (header != null &&
                  header.toLowerCase().startsWith('bearer ')) {
                final used = header.substring(7).trim();
                if (used.isNotEmpty) {
                  final cleared =
                      await clearTokens(onlyIfAccessToken: used);
                  if (cleared) {
                    onSessionExpired?.call();
                  }
                }
              } else {
                // No bearer was sent — session is already gone.
                onSessionExpired?.call();
              }
            }
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final hasAuth = options.headers['Authorization'] != null;
            debugPrint(
              '[vivrant:api] → ${options.method} ${options.uri} auth=$hasAuth',
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[vivrant:api] ← ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            final data = error.response?.data;
            final hasAuth =
                error.requestOptions.headers['Authorization'] != null;
            debugPrint(
              '[vivrant:api] ✖ ${error.response?.statusCode ?? 'no-status'} '
              '${error.requestOptions.uri} auth=$hasAuth '
              'msg=${error.message} body=$data',
            );
            handler.next(error);
          },
        ),
      );
    }
  }

  final FlutterSecureStorage _storage;
  late final Dio _dio;

  /// In-memory copy so requests keep working even if secure-storage races.
  String? _memoryAccessToken;
  String? _memoryRefreshToken;

  /// Called when a protected request gets 401 and the session was cleared.
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  Future<String?> _resolveAccessToken() async {
    if (_memoryAccessToken != null && _memoryAccessToken!.isNotEmpty) {
      return _memoryAccessToken;
    }
    final stored = await _storage.read(key: _tokenKey);
    if (stored != null && stored.isNotEmpty) {
      _memoryAccessToken = stored;
    }
    return stored;
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _memoryAccessToken = accessToken;
    if (refreshToken != null) {
      _memoryRefreshToken = refreshToken;
    }
    await _storage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (kDebugMode) {
      debugPrint(
        '[vivrant:api] tokens saved accessLen=${accessToken.length} '
        'refresh=${refreshToken != null}',
      );
    }
  }

  Future<String?> get accessToken => _resolveAccessToken();

  /// Clears stored JWTs. When [onlyIfAccessToken] is set, clears only if the
  /// current access token still matches (avoids wiping a fresher login).
  /// Returns true when tokens were actually cleared.
  Future<bool> clearTokens({String? onlyIfAccessToken}) async {
    if (onlyIfAccessToken != null) {
      final current = _memoryAccessToken ?? await _storage.read(key: _tokenKey);
      if (current != onlyIfAccessToken) return false;
    }
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    return true;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      _dio.delete<T>(path, data: data);
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Couldn’t reach the server. Check your connection and try again.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 401) return 'Please sign in again.';
        if (code == 403) return 'You don’t have permission to do that.';
        if (code == 404) return 'We couldn’t find what you’re looking for.';
        if (code != null && code >= 500) {
          return 'Something went wrong on our end. Please try again shortly.';
        }
        return 'Request failed. Please try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again.';
      case DioExceptionType.transformTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.unknown:
        break;
    }

    final raw = error.message ?? '';
    if (raw.toLowerCase().contains('timeout') ||
        raw.toLowerCase().contains('aborted')) {
      return 'Connection timed out. Check your network and try again.';
    }
    if (raw.toLowerCase().contains('socket') ||
        raw.toLowerCase().contains('network')) {
      return 'Couldn’t reach the server. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
