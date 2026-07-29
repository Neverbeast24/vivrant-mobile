import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/env.dart';
import '../../config/supabase_bootstrap.dart';
import '../../core/network/api_client.dart';
import '../../data/vivrant_api.dart';
import '../models/models.dart';

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
  AuthNotifier(this._api, this._client)
      : super(const AuthState(status: AuthStatus.unknown)) {
    _client.onSessionExpired = _handleSessionExpired;
    _bootstrap();
  }

  final VivrantApi _api;
  final ApiClient _client;

  void _handleSessionExpired() {
    if (state.status != AuthStatus.authenticated) return;
    if (kDebugMode) {
      debugPrint('[vivrant:auth] session expired — forcing re-login');
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
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
      } catch (_) {
        await _client.clearTokens();
        state = AuthState(
          status: AuthStatus.unauthenticated,
          error: onboarded ? null : 'needs_onboarding',
        );
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
      await _api.login(email: email, password: password);
      final token = await _client.accessToken;
      if (token == null || token.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          error: 'Sign-in succeeded but no session token was saved. Try again.',
        );
        return false;
      }
      final profile = await _api.getProfile();
      if (kDebugMode) {
        debugPrint(
          '[vivrant:auth] login ok user=${profile.displayName} email=${profile.email}',
        );
      }
      state = AuthState(status: AuthStatus.authenticated, profile: profile);
      return true;
    } catch (e) {
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
          if (kDebugMode) {
            debugPrint(
              '[vivrant:auth] oauth ok provider=$provider email=${profile.email}',
            );
          }
          completer.complete(true);
        } catch (e) {
          final message = apiErrorMessage(e);
          state = state.copyWith(
            status: AuthStatus.unauthenticated,
            error: message,
          );
          completer.complete(false);
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
        const Duration(minutes: 5),
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
    await _api.logout();
    try {
      if (await ensureSupabaseInitialized()) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {
      // Local API logout already cleared tokens.
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vivrant_onboarded', true);
    // Clear needs_onboarding so the router can leave /onboarding.
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshProfile() async {
    final profile = await _api.getProfile();
    state = state.copyWith(profile: profile);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(vivrantApiProvider), ref.watch(apiClientProvider));
});
