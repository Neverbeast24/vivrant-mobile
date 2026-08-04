import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';
import '../../config/supabase_bootstrap.dart';
import '../../core/network/api_client.dart';
import '../../core/services/push_service.dart';
import '../../data/vivrant_api.dart';
import '../models/models.dart';
import 'module_cache.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.profile,
    this.error,
  });

  final AuthStatus status;
  final Profile? profile;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    Profile? profile,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._client, this._moduleCache)
      : _push = PushService(_api),
        super(const AuthState(status: AuthStatus.unknown)) {
    _client.onSessionExpired = _handleSessionExpired;
    _bootstrap();
  }

  final VivrantApi _api;
  final ApiClient _client;
  final ModuleCache _moduleCache;
  final PushService _push;

  void _enqueuePushRegistration() {
    // Fire-and-forget; never block or fail auth on push setup.
    Future<void>(() async {
      try {
        await _push.registerIfAvailable();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[vivrant:push] ignored error: $e');
        }
      }
    });
  }

  void _handleSessionExpired() {
    if (state.status != AuthStatus.authenticated) return;
    if (kDebugMode) {
      debugPrint('[vivrant:auth] session expired — forcing re-login');
    }
    // Defer so GoRouter redirect does not tear down overlays mid-frame
    // (Duplicate GlobalKey / dirty build-scope crashes).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (state.status != AuthStatus.authenticated) return;
      _moduleCache.invalidate();
      state = const AuthState(status: AuthStatus.unauthenticated);
    });
  }

  /// Backfills the profile after a soft bootstrap failure (network blip).
  /// Stops on success, on a 401 (handled by the session-expired path), or
  /// once the user is no longer authenticated.
  void _retryProfileInBackground() {
    Future<void>(() async {
      for (final delay in const [
        Duration(seconds: 5),
        Duration(seconds: 20),
        Duration(seconds: 60),
      ]) {
        await Future<void>.delayed(delay);
        if (!mounted) return;
        if (state.status != AuthStatus.authenticated) return;
        if (state.profile != null) return;
        try {
          final profile = await _api.getProfile();
          if (!mounted || state.status != AuthStatus.authenticated) return;
          state = state.copyWith(profile: profile);
          return;
        } catch (e) {
          if (e is DioException && e.response?.statusCode == 401) return;
        }
      }
    });
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboarded = prefs.getBool('vivrant_onboarded') ?? false;
      final token = await _client.accessToken;

      if (token == null || token.isEmpty) {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: onboarded ? null : 'needs_onboarding',
        );
        return;
      }

      try {
        final profile = await _api
            .getProfile()
            .timeout(const Duration(seconds: 12));
        state = AuthState(status: AuthStatus.authenticated, profile: profile);
        _enqueuePushRegistration();
      } catch (e) {
        // Only clear tokens on definitive auth failure. Network/timeouts
        // should keep the session so a blip does not force re-login.
        final status = e is DioException ? e.response?.statusCode : null;
        final hardAuthFail = status == 401 || status == 403;
        if (hardAuthFail) {
          await _client.clearTokens();
          state = AuthState(
            status: AuthStatus.unauthenticated,
            error: onboarded ? null : 'needs_onboarding',
          );
          return;
        }
        if (kDebugMode) {
          debugPrint('[vivrant:auth] bootstrap profile soft-fail: $e');
        }
        // Keep the session and fill the profile in once the network recovers.
        state = const AuthState(status: AuthStatus.authenticated);
        _enqueuePushRegistration();
        _retryProfileInBackground();
      }
    } catch (_) {
      // Storage failures should still leave splash.
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'needs_onboarding',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    if (kDebugMode) {
      debugPrint('[vivrant:auth] login start email=$email');
    }
    try {
      final data = await _api.login(email: email, password: password);
      final token = await _client.accessToken;
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Sign-in succeeded but no session token was saved. Try again.',
        );
        return false;
      }
      // Prefer profile from login response — avoids a second round-trip.
      final profile = _profileFromAuthPayload(data) ?? await _api.getProfile();
      if (kDebugMode) {
        debugPrint(
          '[vivrant:auth] login ok user=${profile.displayName} email=${profile.email}',
        );
      }
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
    } catch (e, st) {
      // StateNotifier applies state before notifying listeners. If a listener
      // throws (e.g. GoRouter refresh), auth is already set — keep the session.
      if (state.status == AuthStatus.authenticated) {
        if (kDebugMode) {
          debugPrint(
            '[vivrant:auth] login ok (ignored listener error): $e\n$st',
          );
        }
        _enqueuePushRegistration();
        return true;
      }
      final message = apiErrorMessage(e);
      if (kDebugMode) {
        debugPrint('[vivrant:auth] login fail: $message\n$e\n$st');
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      return false;
    }
    _enqueuePushRegistration();
    return true;
  }

  Profile? _profileFromAuthPayload(Map<String, dynamic> data) {
    final raw = data['profile'];
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final user = data['user'];
    if (user is Map) {
      map.putIfAbsent('email', () => user['email']);
      map.putIfAbsent('user_id', () => user['id']);
    }
    try {
      return Profile.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Google / GitHub via Supabase OAuth + deep link, then Bearer APIs.
  Future<bool> loginWithOAuth(OAuthProvider provider) async {
    state = state.copyWith(clearError: true);

    final ready = await ensureSupabaseInitialized();
    if (!ready) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error:
            'Supabase not ready. Stop the app and run: flutter run --dart-define-from-file=dart_defines.json',
      );
      return false;
    }

    if (kDebugMode) {
      debugPrint('[vivrant:auth] oauth start provider=$provider');
    }

    try {
      final supabase = Supabase.instance.client;
      final completer = Completer<bool>();
      // Untyped to avoid clashing with our AuthState class name.
      late final StreamSubscription sub;

      sub = supabase.auth.onAuthStateChange.listen((data) async {
        if (data.event != AuthChangeEvent.signedIn) return;
        final session = data.session;
        if (session == null) return;
        if (completer.isCompleted) return;

        try {
          await _client.saveTokens(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
          );
          final profile = await _api.getProfile();
          state = AuthState(status: AuthStatus.authenticated, profile: profile);
          _enqueuePushRegistration();
          if (kDebugMode) {
            debugPrint(
              '[vivrant:auth] oauth ok provider=$provider email=${profile.email}',
            );
          }
          completer.complete(true);
        } catch (e, st) {
          if (state.status == AuthStatus.authenticated) {
            if (kDebugMode) {
              debugPrint(
                '[vivrant:auth] oauth ok (ignored listener error): $e\n$st',
              );
            }
            _enqueuePushRegistration();
            if (!completer.isCompleted) completer.complete(true);
            return;
          }
          final message = apiErrorMessage(e);
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            error: message,
          );
          if (!completer.isCompleted) completer.complete(false);
        } finally {
          await sub.cancel();
        }
      });

      final launched = await supabase.auth.signInWithOAuth(
        provider,
        redirectTo: Env.oauthRedirect,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await sub.cancel();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Could not open the sign-in browser.',
        );
        return false;
      }

      return await completer.future.timeout(
        const Duration(seconds: 90),
        onTimeout: () async {
          await sub.cancel();
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            error: 'Sign-in timed out. Try again.',
          );
          return false;
        },
      );
    } catch (e) {
      final message = e is AuthException ? e.message : e.toString();
      if (kDebugMode) {
        debugPrint('[vivrant:auth] oauth fail: $message');
      }
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: message,
      );
      return false;
    }
  }

  Future<bool> signup({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      await _api.signup(
        email: email,
        password: password,
        displayName: displayName,
      );
      // Many setups require email confirm — try login if session returned.
      try {
        await _api.login(email: email, password: password);
        final profile = await _api.getProfile();
        state = AuthState(status: AuthStatus.authenticated, profile: profile);
        _enqueuePushRegistration();
      } catch (_) {
        state = const AuthState(
          status: AuthStatus.unauthenticated,
          error: 'Check your email to confirm your account, then sign in.',
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: apiErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    await _push.unregister();
    await _api.logout();
    try {
      if (await ensureSupabaseInitialized()) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      // Local API logout already cleared tokens.
    }
    _moduleCache.invalidate();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vivrant_onboarded', true);
    // Clear needs_onboarding so the router can leave /onboarding.
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile([Profile? profile]) async {
    final next = profile ?? await _api.getProfile();
    state = state.copyWith(profile: next);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(vivrantApiProvider),
    ref.watch(apiClientProvider),
    ref.watch(moduleCacheProvider),
  );
});
