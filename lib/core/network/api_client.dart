import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/env.dart';

const _tokenKey = 'vivrant_access_token';
const _refreshKey = 'vivrant_refresh_token';
const _sessionStartedKey = 'vivrant_session_started_at';

/// Absolute session lifetime before the user must sign in again.
/// Silent token refresh does not extend this window.
const sessionMaxAge = Duration(minutes: 15);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
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
          final path = options.path;
          final isAuthEndpoint = path.contains('/api/auth/login') ||
              path.contains('/api/auth/signup') ||
              path.contains('/api/auth/forgot-password') ||
              path.contains('/api/mobile/auth/refresh');

          if (!isAuthEndpoint) {
            await loadSessionClock();
            if (isSessionExpired) {
              if (kDebugMode) {
                debugPrint(
                  '[vivrant:api] blocked expired session → ${options.method} $path',
                );
              }
              await clearTokens();
              onSessionExpired?.call();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'session_expired',
                  message: 'Session expired. Please sign in again.',
                ),
              );
            }
          }

          final token = await _resolveAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final path = error.requestOptions.path;
          final isAuthEndpoint = path.contains('/api/auth/login') ||
              path.contains('/api/auth/signup') ||
              path.contains('/api/mobile/auth/refresh');
          if (isAuthEndpoint) {
            return handler.next(error);
          }

          final alreadyRetried =
              error.requestOptions.extra['_vivrantRetried'] == true;
          if (!alreadyRetried) {
            final refreshOutcome = await _refreshSession();
            if (refreshOutcome == _RefreshOutcome.success) {
              final opts = error.requestOptions;
              opts.extra['_vivrantRetried'] = true;
              final token = await _resolveAccessToken();
              if (token != null && token.isNotEmpty) {
                opts.headers['Authorization'] = 'Bearer $token';
              }
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } on DioException catch (retryError) {
                // Retry went through interceptors; 401 expiry already handled.
                return handler.next(retryError);
              }
            }
            // Network/timeout during refresh — keep tokens; surface the error.
            if (refreshOutcome == _RefreshOutcome.transient) {
              return handler.next(error);
            }
          }

          // Refresh rejected (401/403) or retry still 401 — clear only the
          // token that failed (never wipe a newer session from a concurrent login).
          final header =
              error.requestOptions.headers['Authorization']?.toString();
          if (header != null && header.toLowerCase().startsWith('bearer ')) {
            final used = header.substring(7).trim();
            if (used.isNotEmpty) {
              final cleared = await clearTokens(onlyIfAccessToken: used);
              if (cleared) onSessionExpired?.call();
            }
          } else {
            onSessionExpired?.call();
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
            final hasAuth =
                error.requestOptions.headers['Authorization'] != null;
            final status = error.response?.statusCode;
            // Never log response bodies — they can include tokens / PII.
            debugPrint(
              '[vivrant:api] ✖ ${status ?? 'no-status'} '
              '${error.requestOptions.uri} auth=$hasAuth '
              'type=${error.type.name}',
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
  DateTime? _memorySessionStartedAt;

  /// Shared in-flight refresh so concurrent 401s only hit the endpoint once.
  Future<_RefreshOutcome>? _refreshInFlight;

  /// Called when a protected request gets 401 and the session was cleared.
  void Function()? onSessionExpired;

  /// UTC timestamp when the current login session began (null if logged out).
  DateTime? get sessionStartedAt => _memorySessionStartedAt;

  /// Remaining time until forced re-login, or [Duration.zero] if already due.
  Duration get sessionTimeRemaining {
    final started = _memorySessionStartedAt;
    if (started == null) return Duration.zero;
    final remaining = sessionMaxAge - DateTime.now().toUtc().difference(started);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isSessionExpired {
    final started = _memorySessionStartedAt;
    if (started == null) return false;
    return DateTime.now().toUtc().difference(started) >= sessionMaxAge;
  }

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

  Future<String?> _resolveRefreshToken() async {
    if (_memoryRefreshToken != null && _memoryRefreshToken!.isNotEmpty) {
      return _memoryRefreshToken;
    }
    final stored = await _storage.read(key: _refreshKey);
    if (stored != null && stored.isNotEmpty) {
      _memoryRefreshToken = stored;
    }
    return stored;
  }

  /// Exchange the stored refresh token for a new access token.
  Future<_RefreshOutcome> _refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<_RefreshOutcome> _doRefresh() async {
    await loadSessionClock();
    if (isSessionExpired) {
      if (kDebugMode) {
        debugPrint(
          '[vivrant:api] refresh blocked — session older than $sessionMaxAge',
        );
      }
      // Leave clearing to the 401 interceptor so onSessionExpired still fires.
      return _RefreshOutcome.invalid;
    }

    final refresh = await _resolveRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      if (kDebugMode) {
        debugPrint('[vivrant:api] refresh skipped — no refresh token');
      }
      return _RefreshOutcome.invalid;
    }

    try {
      // Bare client avoids this interceptor (no 401 → refresh loop).
      final bare = Dio(
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
      final res = await bare.post<Map<String, dynamic>>(
        '/api/mobile/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = res.data;
      final access = data?['access_token'] as String?;
      if (access == null || access.isEmpty) {
        if (kDebugMode) {
          debugPrint('[vivrant:api] refresh response missing access_token');
        }
        return _RefreshOutcome.invalid;
      }
      await saveTokens(
        accessToken: access,
        refreshToken: data?['refresh_token'] as String?,
      );
      if (kDebugMode) {
        debugPrint('[vivrant:api] session refreshed');
      }
      return _RefreshOutcome.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (kDebugMode) {
        debugPrint('[vivrant:api] refresh failed status=$status: $e');
      }
      if (status == 401 || status == 403) {
        return _RefreshOutcome.invalid;
      }
      // Timeouts / connection errors — keep session tokens.
      return _RefreshOutcome.transient;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[vivrant:api] refresh failed: $e');
      }
      return _RefreshOutcome.transient;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    bool startNewSession = false,
  }) async {
    _memoryAccessToken = accessToken;
    if (refreshToken != null) {
      _memoryRefreshToken = refreshToken;
    }
    await _storage.write(key: _tokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (startNewSession) {
      await _writeSessionStart(DateTime.now().toUtc());
    }
    if (kDebugMode) {
      debugPrint(
        '[vivrant:api] tokens saved accessLen=${accessToken.length} '
        'refresh=${refreshToken != null} newSession=$startNewSession',
      );
    }
  }

  Future<String?> get accessToken => _resolveAccessToken();

  /// Loads (or migrates) the session-start clock from secure storage.
  /// Existing installs without a stamp get a fresh clock so they are not
  /// logged out immediately after upgrading.
  Future<void> loadSessionClock() async {
    if (_memorySessionStartedAt != null) return;
    final raw = await _storage.read(key: _sessionStartedKey);
    if (raw != null && raw.isNotEmpty) {
      final millis = int.tryParse(raw);
      if (millis != null) {
        _memorySessionStartedAt =
            DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
        return;
      }
    }
    final token = await _resolveAccessToken();
    if (token != null && token.isNotEmpty) {
      await _writeSessionStart(DateTime.now().toUtc());
    }
  }

  Future<void> _writeSessionStart(DateTime startedAt) async {
    _memorySessionStartedAt = startedAt;
    await _storage.write(
      key: _sessionStartedKey,
      value: startedAt.millisecondsSinceEpoch.toString(),
    );
  }

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
    _memorySessionStartedAt = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _sessionStartedKey);
    return true;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) =>
      _dio.get<T>(path, queryParameters: query, options: options);

  Future<Response<T>> post<T>(String path, {Object? data, Options? options}) =>
      _dio.post<T>(path, data: data, options: options);

  Future<Response<T>> patch<T>(String path, {Object? data, Options? options}) =>
      _dio.patch<T>(path, data: data, options: options);

  Future<Response<T>> put<T>(String path, {Object? data, Options? options}) =>
      _dio.put<T>(path, data: data, options: options);

  Future<Response<T>> delete<T>(String path, {Object? data, Options? options}) =>
      _dio.delete<T>(path, data: data, options: options);

  /// Multipart upload — clears the default JSON content-type so Dio can set
  /// the multipart boundary correctly.
  Future<Response<T>> postMultipart<T>(
    String path,
    FormData data, {
    Options? options,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        options: (options ?? Options()).copyWith(
          contentType: 'multipart/form-data',
        ),
      );

  /// Longer receive window for Gemini-backed endpoints.
  static Options get aiOptions => Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
      );
}

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (data is Map && data['error'] is Map) {
      final nested = data['error'] as Map;
      if (nested['message'] is String) return nested['message'] as String;
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

enum _RefreshOutcome { success, invalid, transient }
