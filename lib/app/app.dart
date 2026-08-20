import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../core/theme/theme.dart';
import '../core/widgets/app_snackbar.dart';
import '../shared/providers/auth_provider.dart';
import '../shared/providers/theme_provider.dart';
import 'router.dart';

/// Root widget: theme, router, snackbar messenger, and idle-session warning.
class VivrantApp extends ConsumerWidget {
  const VivrantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final idleSeconds = ref.watch(
      authProvider.select((s) => s.idleWarningSeconds),
    );
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: VivrantTheme.light(),
      darkTheme: VivrantTheme.dark(),
      themeMode: themeMode,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      routerConfig: router,
      builder: (context, child) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            ref.read(authProvider.notifier).noteUserActivity();
          },
          onPointerSignal: (_) {
            ref.read(authProvider.notifier).noteUserActivity();
          },
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (idleSeconds != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _IdleWarningBanner(
                    secondsLeft: idleSeconds,
                    onStay: () =>
                        ref.read(authProvider.notifier).staySignedIn(),
                    panelColor: colorScheme.surfaceContainerHigh,
                    ink: colorScheme.onSurface,
                    muted: colorScheme.onSurfaceVariant,
                    accent: colorScheme.primary,
                  )
                      .animate()
                      .fadeIn(duration: 280.ms)
                      .slideY(
                        begin: 0.12,
                        end: 0,
                        duration: 380.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _IdleWarningBanner extends StatelessWidget {
  const _IdleWarningBanner({
    required this.secondsLeft,
    required this.onStay,
    required this.panelColor,
    required this.ink,
    required this.muted,
    required this.accent,
  });

  final int secondsLeft;
  final VoidCallback onStay;
  final Color panelColor;
  final Color ink;
  final Color muted;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(20),
      color: panelColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Still there? You’ll be signed out in ${secondsLeft}s.',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'For your privacy, we sign you out after 10 minutes without activity.',
              style: TextStyle(
                color: muted,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: onStay,
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: VivrantColors.of(context).onAccent,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                child: const Text('Stay signed in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
