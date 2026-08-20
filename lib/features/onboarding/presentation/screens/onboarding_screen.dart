import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _pages = [
    (
      title: 'Every choice shapes your health',
      body:
          'VIVRΛNT turns nutrition, movement, gym, sleep, and spending into clear next steps—not just charts.',
      icon: Icons.spa_rounded,
    ),
    (
      title: 'Track what matters',
      body:
          'Log meals, workouts, hydration, habits, groceries, and pantry stock in one botanical workspace.',
      icon: Icons.favorite_outline,
    ),
    (
      title: 'Ask VIVRΛNT',
      body:
          'AI coaching for meals, gym plans, grocery lists, spending, weekly summaries, and reminders.',
      icon: Icons.auto_awesome,
    ),
  ];

  Future<void> _finish() async {
    await ref.read(authProvider.notifier).completeOnboarding();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: VivrantBrand(),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  final c = VivrantColors.of(context);
                  return Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                c.accentSoft,
                                c.accent.withValues(alpha: 0.22),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: c.accent.withValues(alpha: 0.22),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            page.icon,
                            size: 42,
                            color: c.accent,
                          ),
                        )
                            .animate(key: ValueKey('icon-$i'))
                            .fadeIn(duration: 420.ms)
                            .scale(
                              begin: const Offset(0.86, 0.86),
                              end: const Offset(1, 1),
                              duration: 520.ms,
                              curve: VivrantMotion.spring,
                            ),
                        const SizedBox(height: 28),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        )
                            .animate(key: ValueKey('title-$i'))
                            .fadeIn(delay: 80.ms, duration: 420.ms)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              delay: 80.ms,
                              duration: 480.ms,
                              curve: VivrantMotion.enter,
                            ),
                        const SizedBox(height: 14),
                        Text(
                          page.body,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: c.muted,
                                  ),
                        )
                            .animate(key: ValueKey('body-$i'))
                            .fadeIn(delay: 140.ms, duration: 420.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                final c = VivrantColors.of(context);
                return AnimatedContainer(
                  duration: VivrantMotion.base,
                  curve: VivrantMotion.enter,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? c.accent : c.ink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: c.accent.withValues(alpha: 0.35),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              child: PrimaryButton(
                label: _index < _pages.length - 1 ? 'Continue' : 'Get started',
                icon: _index < _pages.length - 1
                    ? Icons.arrow_forward_rounded
                    : Icons.spa_rounded,
                onPressed: () {
                  if (_index < _pages.length - 1) {
                    _controller.nextPage(
                      duration: VivrantMotion.base,
                      curve: VivrantMotion.enter,
                    );
                  } else {
                    _finish();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
