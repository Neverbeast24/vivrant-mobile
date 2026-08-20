import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'config/supabase_bootstrap.dart';

/// App entry. Initializes bindings + optional Supabase, then runs [VivrantApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureSupabaseInitialized();
  runApp(const ProviderScope(child: VivrantApp()));
}
