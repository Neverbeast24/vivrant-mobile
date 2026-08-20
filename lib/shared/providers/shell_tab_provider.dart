import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom-nav tab index inside [AppShell].
/// Used so Nutrition / Move / Ask defer their first API load until selected.
final shellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Fractional footer/page position (e.g. 1.35 while swiping Nutrition → Training).
/// Updated without rebuilding the whole shell so the pill can track the finger.
final shellTabPositionProvider = Provider<ValueNotifier<double>>((ref) {
  final notifier = ValueNotifier<double>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});
