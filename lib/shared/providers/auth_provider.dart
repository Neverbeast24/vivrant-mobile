import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
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
    this.idleWarningSeconds,
  });

  final AuthStatus status;
  final Profile? profile;
  final String? error;

  /// Seconds until idle logout; non-null only inside the warning window.
  final int? idleWarningSeconds;

  AuthState copyWith({
    AuthStatus? status,
    Profile? profile,
    String? error,
    bool clearError = false,
    int? idleWarningSeconds,
    bool clearIdleWarning = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: clearError ? null : (error ?? this.error),
      idleWarningSeconds: clearIdleWarning
          ? null
          : (idleWarningSeconds ?? this.idleWarningSeconds),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._client, this._moduleCache)
      : _push = PushService(_api),
        super(const AuthState(status: AuthStatus.unknown)) {
    _client.onSessionExpired = _handleSessionExpired;
    _lifecycleObserver = _AppLifecycleObserver(_checkSessionTimeout);
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _bootstrap();
  }

  final VivrantApi _api;
  final ApiClient _client;
  final ModuleCache _moduleCache;
  final PushService _push;
  late final _AppLifecycleObserver _lifecycleObserver;
  Timer? _sessionTimer;
  Timer? _warnArmTimer;
  Timer? _idleTickTimer;
  DateTime? _lastActivityNoteAt;

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _warnArmTimer?.cancel();
    _idleTickTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

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

  void _armSessionTimer() {
    _sessionTimer?.cancel();
    _warnArmTimer?.cancel();
    _idleTickTimer?.cancel();
    if (state.status != AuthStatus.authenticated) {
      if (state.idleWarningSeconds != null) {
        state = state.copyWith(clearIdleWarning: true);
      }
      return;
    }
    final remaining = _client.sessionTimeRemaining;
    if (remaining <= Duration.zero) {
      unawaited(_expireSession());
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[vivrant:auth] idle timer armed for ${remaining.inMinutes}m '
        '${remaining.inSeconds % 60}s',
      );
    }
    _sessionTimer = Timer(remaining, () {
      unawaited(_expireSession());
    });

    if (remaining <= sessionIdleWarnBefore) {
      _startIdleTick();
    } else {
      if (state.idleWarningSeconds != null) {
        state = state.copyWith(clearIdleWarning: true);
      }
      _warnArmTimer = Timer(remaining - sessionIdleWarnBefore, _startIdleTick);
    }
  }

  void _startIdleTick() {
    _idleTickTimer?.cancel();
    if (state.status != AuthStatus.authenticated) return;
    void tick() {
      if (state.status != AuthStatus.authenticated) {
        _idleTickTimer?.cancel();
        return;
      }
      final rem = _client.sessionTimeRemaining;
      if (rem <= Duration.zero) {
        unawaited(_expireSession());
        return;
      }
      if (rem <= sessionIdleWarnBefore) {
        final seconds = rem.inSeconds.clamp(1, sessionIdleWarnBefore.inSeconds);
        if (state.idleWarningSeconds != seconds) {
          state = state.copyWith(idleWarningSeconds: seconds);
        }
      } else if (state.idleWarningSeconds != null) {
        state = state.copyWith(clearIdleWarning: true);
      }
    }

    tick();
    _idleTickTimer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  /// Resets the idle clock on user interaction (taps, scrolls, etc.).
  void noteUserActivity() {
    if (state.status != AuthStatus.authenticated) return;
    final now = DateTime.now();
    if (_lastActivityNoteAt != null &&
        now.difference(_lastActivityNoteAt!) < const Duration(seconds: 1)) {
      return;
    }
    _lastActivityNoteAt = now;
    unawaited(_client.touchActivity());
    _armSessionTimer();
  }

  /// Explicit stay-signed-in from the idle warning banner.
  void staySignedIn() {
    if (state.status != AuthStatus.authenticated) return;
    _lastActivityNoteAt = null;
    noteUserActivity();
  }

  Future<void> _checkSessionTimeout() async {
    if (state.status != AuthStatus.authenticated) return;
    await _client.loadSessionClock();
    if (_client.isSessionExpired) {
      await _expireSession();
      return;
    }
    _armSessionTimer();
  }

  Future<void> _expireSession() async {
    if (state.status != AuthStatus.authenticated) return;
    if (kDebugMode) {
      debugPrint('[vivrant:auth] idle session timeout — forcing re-login');
    }
    _sessionTimer?.cancel();
    _warnArmTimer?.cancel();
    _idleTickTimer?.cancel();
    await _client.clearTokens();
    try {
      if (await ensureSupabaseInitialized()) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      // Local tokens already cleared.
    }
    _handleSessionExpired(
      message: 'Signed out after 10 minutes of inactivity. Please sign in again.',
    );
  }

  void _handleSessionExpired({String? message}) {
    if (state.status != AuthStatus.authenticated) return;
    if (kDebugMode) {
      debugPrint('[vivrant:auth] session expired — forcing re-login');
    }
    _sessionTimer?.cancel();
    _warnArmTimer?.cancel();
    _idleTickTimer?.cancel();
    // Tear down any Supabase OAuth session as well (best-effort).
    unawaited(() async {
      try {
        if (await ensureSupabaseInitialized()) {
          await Supabase.instance.client.auth.signOut();
        }
      } catch (_) {}
    }());
    // Defer so GoRouter redirect does not tear down overlays mid-frame
    // (Duplicate GlobalKey / dirty build-scope crashes).
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (state.status != AuthStatus.authenticated) return;
      _moduleCache.invalidate();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: message,
      );
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

      await _client.loadSessionClock();
      if (_client.isSessionExpired) {
        await _client.clearTokens();
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: onboarded
              ? 'Signed out after 10 minutes of inactivity. Please sign in again.'
              : 'needs_onboarding',
        );
        return;
      }

      try {
        final profile = await _api
            .getProfile()
            .timeout(const Duration(seconds: 12));
        state = AuthState(status: AuthStatus.authenticated, profile: profile);
        _armSessionTimer();
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
        _armSessionTimer();
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
      debugPrint('[vivrant:auth] login start');
    }
    try {
      final data = await _api.login(email: email, password: password);
      final token = await _client.accessToken;
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Sign-in didn’t finish. Please try again.',
        );
        return false;
      }
      // Prefer profile from login response — avoids a second round-trip.
      final profile = _profileFromAuthPayload(data) ?? await _api.getProfile();
      if (kDebugMode) {
        debugPrint('[vivrant:auth] login ok');
      }
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
      _armSessionTimer();
    } catch (e) {
      // StateNotifier applies state before notifying listeners. If a listener
      // throws (e.g. GoRouter refresh), auth is already set — keep the session.
      if (state.status == AuthStatus.authenticated) {
        if (kDebugMode) {
          debugPrint(
            '[vivrant:auth] login ok (ignored listener error)',
          );
        }
        _armSessionTimer();
        _enqueuePushRegistration();
        return true;
      }
      final message = apiErrorMessage(e);
      if (kDebugMode) {
        debugPrint('[vivrant:auth] login fail: $message');
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
            'Google sign-in isn’t available on this build. Please use email instead.',
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
            startNewSession: true,
          );
          final profile = await _api.getProfile();
          state = AuthState(status: AuthStatus.authenticated, profile: profile);
          _armSessionTimer();
          _enqueuePushRegistration();
          if (kDebugMode) {
            debugPrint('[vivrant:auth] oauth ok provider=$provider');
          }
          completer.complete(true);
        } catch (e) {
          if (state.status == AuthStatus.authenticated) {
            if (kDebugMode) {
              debugPrint(
                '[vivrant:auth] oauth ok (ignored listener error)',
              );
            }
            _armSessionTimer();
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
        _armSessionTimer();
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
    _sessionTimer?.cancel();
    _warnArmTimer?.cancel();
    _idleTickTimer?.cancel();
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

class _AppLifecycleObserver with WidgetsBindingObserver {
  _AppLifecycleObserver(this._onResumed);

  final Future<void> Function() _onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResumed());
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(vivrantApiProvider),
    ref.watch(apiClientProvider),
    ref.watch(moduleCacheProvider),
  );
});
