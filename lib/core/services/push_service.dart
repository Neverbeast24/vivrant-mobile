import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../data/vivrant_api.dart';

/// Registers an FCM device token with the backend when Firebase is configured.
///
/// Silently no-ops if `google-services.json` / Firebase options are missing.
class PushService {
  PushService(this._api);

  final VivrantApi _api;
  String? _token;

  Future<void> registerIfAvailable() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[vivrant:push] Firebase not configured — skipping ($e)');
      }
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;

      final platform = Platform.isIOS
          ? 'ios'
          : Platform.isAndroid
              ? 'android'
              : 'web';
      await _api.registerDeviceToken(token: token, platform: platform);
      _token = token;

      messaging.onTokenRefresh.listen((next) async {
        try {
          _token = next;
          await _api.registerDeviceToken(token: next, platform: platform);
        } catch (e) {
          if (kDebugMode) {
            debugPrint('[vivrant:push] token refresh failed: $e');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[vivrant:push] register failed: $e');
      }
    }
  }

  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await _api.unregisterDeviceToken(token);
    } catch (_) {
      // Best-effort on logout.
    }
    _token = null;
  }
}
