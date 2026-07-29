import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../core/theme/theme.dart';
import '../core/widgets/app_snackbar.dart';
import '../shared/providers/theme_provider.dart';
import 'router.dart';

class VivrantApp extends ConsumerWidget {
  const VivrantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: VivrantTheme.light(),
      darkTheme: VivrantTheme.dark(),
      themeMode: themeMode,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
