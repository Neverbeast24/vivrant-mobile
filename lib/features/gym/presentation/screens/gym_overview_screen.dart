import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';
import '../widgets/gym_nav_card.dart';

class GymOverviewScreen extends ConsumerStatefulWidget {
  const GymOverviewScreen({super.key});

  @override
  ConsumerState<GymOverviewScreen> createState() => _GymOverviewScreenState();
}

class _GymOverviewScreenState extends ConsumerState<GymOverviewScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.gymOverview);
    if (cached != null) {
      _data = Map<String, dynamic>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final showSpinner = _data == null;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(vivrantApiProvider).gymOverview();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymOverview, data);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  int _n(String key) => (_data?[key] as num?)?.toInt() ?? 0;

  Animation<double> _fade(double begin, double end) {
    return CurvedAnimation(
      parent: _enter,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _reveal({
    required double start,
    required double finish,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fade(start, finish),
      child: SlideTransition(
        position: _slide(start, finish),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;

    final sessions = _n('sessionCount');
    final minutes = _n('totalMinutes');
    final calories = _n('totalCalories');
    final machines = _n('machineCount');
    final demos = _n('demoCount');
    final plans = _n('planCount');

    return GradientScaffold(
      appBar: AppBar(title: const Text('Gym')),
      child: Stack(
        children: [
          const _GymAtmosphere(),
          RefreshIndicator(
            onRefresh: _load,
            color: accent,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                _reveal(
                  start: 0.0,
                  finish: 0.42,
                  child: const PageHeader(
                    eyebrow: 'Training',
                    title: 'Train with',
                    highlight: 'intent',
                  ),
                ),
                _reveal(
                  start: 0.06,
                  finish: 0.48,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Start with demos, then log sessions and build a program when you are ready.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: muted,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (_error != null)
                  _reveal(
                    start: 0.1,
                    finish: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: EmptyState(
                        message: _error!,
                        action: OutlinedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ),
                  )
                else
                  _reveal(
                    start: 0.1,
                    finish: 0.55,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: _StatsStrip(
                        loading: _loading,
                        sessions: sessions,
                        minutes: minutes,
                        calories: calories,
                        machines: machines,
                      ),
                    ),
                  ),
                // Destinations stay reachable even when overview stats fail.
                _reveal(
                  start: 0.2,
                  finish: 0.62,
                  child: const SectionLabel('Explore'),
                ),
                _reveal(
                  start: 0.24,
                  finish: 0.7,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                    children: [
                      GymNavCard(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Exercise demos',
                        caption: demos > 0
                            ? '$demos form clips'
                            : 'Free-weight & bodyweight',
                        path: '/gym/demos',
                        featured: true,
                      ),
                      GymNavCard(
                        icon: Icons.precision_manufacturing_outlined,
                        label: 'Machines',
                        caption: machines > 0
                            ? '$machines guided demos'
                            : 'Equipment walkthroughs',
                        path: '/gym/machines',
                      ),
                      GymNavCard(
                        icon: Icons.history_rounded,
                        label: 'Sessions',
                        caption: sessions > 0
                            ? '$sessions logged recently'
                            : 'Log & review workouts',
                        path: '/gym/sessions',
                      ),
                      GymNavCard(
                        icon: Icons.auto_awesome_rounded,
                        label: 'Training program',
                        caption: plans > 0
                            ? '$plans saved program${plans == 1 ? '' : 's'}'
                            : 'AI programs & routines',
                        path: '/gym/plans',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _reveal(
                  start: 0.4,
                  finish: 0.85,
                  child: _SoftCard(
                    color: panel,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Quick start',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '1) Watch a beginner demo · 2) Log a light session · 3) Ask AI for machine picks when you want a circuit.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: muted,
                            height: 1.45,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        PrimaryButton(
                          label: 'Watch beginner demos',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            context.push('/gym/demos');
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _GhostAction(
                                label: 'Log session',
                                ink: ink,
                                onTap: () => context.push('/gym/sessions'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _GhostAction(
                                label: 'Browse machines',
                                ink: ink,
                                onTap: () => context.push('/gym/machines'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.loading,
    required this.sessions,
    required this.minutes,
    required this.calories,
    required this.machines,
  });

  final bool loading;
  final int sessions;
  final int minutes;
  final int calories;
  final int machines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _StatChip(
            label: 'Sessions',
            value: loading ? '—' : '$sessions',
            caption: 'Logged',
            icon: Icons.fitness_center_rounded,
            featured: true,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Minutes',
            value: loading ? '—' : '$minutes',
            caption: 'Training time',
            icon: Icons.timer_outlined,
            soft: true,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Calories',
            value: loading ? '—' : '$calories',
            caption: 'From sessions',
            icon: Icons.local_fire_department_outlined,
            warm: true,
          ),
          const SizedBox(width: 10),
          _StatChip(
            label: 'Machines',
            value: loading ? '—' : '$machines',
            caption: 'Demos ready',
            icon: Icons.precision_manufacturing_outlined,
            soft: true,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    this.featured = false,
    this.soft = false,
    this.warm = false,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final bool featured;
  final bool soft;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;

    Color bg;
    Color fg;
    Color iconColor;
    if (featured) {
      bg = Colors.transparent;
      fg = Colors.white;
      iconColor = Colors.white;
    } else if (warm) {
      bg = const Color(0x1AE07A3D);
      fg = const Color(0xFFB85C28);
      iconColor = fg;
    } else if (soft) {
      bg = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;
      fg = dark ? VivrantColors.darkAccent : VivrantColors.accentDeep;
      iconColor = fg;
    } else {
      bg = (dark ? VivrantColors.darkPanel : Colors.white)
          .withValues(alpha: 0.96);
      fg = ink;
      iconColor = accent;
    }

    return Container(
      width: 132,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: featured
            ? (dark
                ? VivrantColors.darkBrandGradient
                : VivrantColors.brandGradient)
            : null,
        color: featured ? null : bg,
        borderRadius: BorderRadius.circular(20),
        border: featured
            ? null
            : Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(
              alpha: featured ? 0.18 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: featured
                        ? Colors.white.withValues(alpha: 0.85)
                        : muted,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: featured
                  ? Colors.white.withValues(alpha: 0.78)
                  : muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (dark ? VivrantColors.darkAccent : VivrantColors.accent)
                .withValues(alpha: dark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _GhostAction extends StatelessWidget {
  const _GhostAction({
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final String label;
  final Color ink;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ink.withValues(alpha: 0.12)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: ink.withValues(alpha: 0.72),
            ),
          ),
        ),
      ),
    );
  }
}

class _GymAtmosphere extends StatelessWidget {
  const _GymAtmosphere();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final c = dark ? VivrantColors.darkCyan : VivrantColors.cyan;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -80,
            child: _Blob(
              size: 220,
              color: a.withValues(alpha: dark ? 0.16 : 0.1),
            ),
          ),
          Positioned(
            top: 320,
            left: -100,
            child: _Blob(
              size: 200,
              color: c.withValues(alpha: dark ? 0.12 : 0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
