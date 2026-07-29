import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active bottom-nav tab index inside [AppShell].
/// Used so Nutrition / Move / Ask defer their first API load until selected.
final shellTabIndexProvider = StateProvider<int>((ref) => 0);
