import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Project publishable key (safe for clients). Used when dart-defines were
/// missing at process start — [String.fromEnvironment] is compile-time only.
const _fallbackPublishableKey =
    'sb_publishable_LZIrdY7BOosvGebRjMPMeA_rgP_uKzJ';

bool _initializing = false;
bool _ready = false;

/// Ensures [Supabase.initialize] has run. Safe to call multiple times.
///
/// Hot reload does not re-run [main], so OAuth buttons call this before use.
/// Never read [Supabase.instance] until this returns true — the getter asserts.
Future<bool> ensureSupabaseInitialized() async {
  if (_ready) return true;

  final key = Env.supabaseAnonKey.isNotEmpty
      ? Env.supabaseAnonKey
      : _fallbackPublishableKey;

  if (key.isEmpty) {
    if (kDebugMode) {
      debugPrint('[vivrant] supabase skipped — empty publishable key');
    }
    return false;
  }

  while (_initializing) {
    await Future<void>.delayed(const Duration(milliseconds: 40));
    if (_ready) return true;
  }

  if (_ready) return true;

  _initializing = true;
  try {
    // Idempotent: supabase_flutter skips when already initialized.
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: key,
    );
    _ready = true;
    if (kDebugMode) {
      debugPrint(
        '[vivrant] supabase ready host=${Uri.parse(Env.supabaseUrl).host}',
      );
    }
    return true;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[vivrant] supabase init failed: $e');
      debugPrint('$st');
    }
    return false;
  } finally {
    _initializing = false;
  }
}
