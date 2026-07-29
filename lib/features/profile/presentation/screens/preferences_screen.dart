import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/auth_provider.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  final _steps = TextEditingController(text: '8000');
  final _water = TextEditingController(text: '2500');
  bool _loading = false;
  bool _synced = false;
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic));
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _steps.dispose();
    _water.dispose();
    super.dispose();
  }

  void _sync(Profile? profile) {
    if (_synced || profile == null) return;
    _steps.text = '${profile.dailyStepGoal}';
    _water.text = '${profile.dailyWaterGoalMl}';
    _synced = true;
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).savePreferences({
        'daily_step_goal': int.tryParse(_steps.text) ?? 8000,
        'daily_water_goal_ml': int.tryParse(_water.text) ?? 2500,
      });
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.showSuccess('Preferences saved');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    _sync(profile);

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Preferences')),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const PageHeader(
                eyebrow: 'Settings',
                title: 'Daily',
                highlight: 'targets',
              ),
              Text(
                'Tune the everyday defaults that keep your rhythm steady.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: panel.withValues(alpha: dark ? 0.92 : 0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: ink.withValues(alpha: 0.06)),
                  boxShadow: [
                    BoxShadow(
                      color: VivrantColors.accent
                          .withValues(alpha: dark ? 0.08 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PrefHint(
                      icon: Icons.directions_walk_rounded,
                      label: 'Movement',
                      soft: soft,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _steps,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Daily step goal',
                        hintText: '8000',
                        prefixIcon: Icon(
                          Icons.directions_walk_rounded,
                          size: 20,
                          color: muted,
                        ),
                        suffixText: 'steps',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PrefHint(
                      icon: Icons.water_drop_outlined,
                      label: 'Hydration',
                      soft: soft,
                      accent: accent,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _water,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Daily water goal',
                        hintText: '2500',
                        prefixIcon: Icon(
                          Icons.water_drop_outlined,
                          size: 20,
                          color: muted,
                        ),
                        suffixText: 'ml',
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _loading ? 'Saving…' : 'Save preferences',
                      loading: _loading,
                      onPressed: _save,
                      icon: Icons.check_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrefHint extends StatelessWidget {
  const _PrefHint({
    required this.icon,
    required this.label,
    required this.soft,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color soft;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: accent),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: accent,
          ),
        ),
      ],
    );
  }
}
