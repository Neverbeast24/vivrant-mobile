import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/providers/theme_provider.dart';

class PreferencesScreen extends ConsumerStatefulWidget {
  const PreferencesScreen({super.key});

  @override
  ConsumerState<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends ConsumerState<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  final _timezone = TextEditingController(text: 'Asia/Manila');
  String _theme = 'system';
  bool _notifications = true;
  bool _weeklyReport = true;
  bool _loading = false;
  bool _loadingPrefs = false;
  late final AnimationController _enter;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _themeOptions = <(String, String)>[
    ('light', 'Light'),
    ('dark', 'Dark'),
    ('system', 'System'),
  ];

  static const _timezoneOptions = <String>[
    'Asia/Manila',
    'Asia/Singapore',
    'Asia/Tokyo',
    'Asia/Hong_Kong',
    'Asia/Bangkok',
    'Asia/Jakarta',
    'Australia/Sydney',
    'Pacific/Auckland',
    'Europe/London',
    'Europe/Paris',
    'America/New_York',
    'America/Los_Angeles',
    'America/Chicago',
    'UTC',
  ];

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
    // Seed from local auth/theme so the form paints immediately.
    final auth = ref.read(authProvider).profile;
    final localTheme = themeModeToString(ref.read(themeModeProvider));
    _theme = localTheme;
    _timezone.text = auth?.timezone ?? 'Asia/Manila';
    _loadingPrefs = false;
    _enter.forward();
    _load();
  }

  @override
  void dispose() {
    _enter.dispose();
    _timezone.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadingPrefs = true);
    try {
      final settings = await ref.read(vivrantApiProvider).getPreferences();
      if (!mounted) return;
      setState(() {
        _theme = (settings['theme'] as String?) ?? 'system';
        _notifications = settings['notifications_enabled'] as bool? ?? true;
        _weeklyReport = settings['weekly_report_enabled'] as bool? ?? true;
        _timezone.text = (settings['timezone'] as String?) ??
            ref.read(authProvider).profile?.timezone ??
            'Asia/Manila';
        _loadingPrefs = false;
      });
      await ref.read(themeModeProvider.notifier).setThemeFromPreference(_theme);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _timezone.text =
            ref.read(authProvider).profile?.timezone ?? 'Asia/Manila';
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).savePreferences({
        'theme': _theme,
        'notifications_enabled': _notifications,
        'weekly_report_enabled': _weeklyReport,
        'timezone': _timezone.text.trim().isEmpty
            ? 'Asia/Manila'
            : _timezone.text.trim(),
      });
      await ref.read(themeModeProvider.notifier).setThemeFromPreference(_theme);
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
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    final tzValue = _timezoneOptions.contains(_timezone.text)
        ? _timezone.text
        : null;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Preferences')),
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: ListView(
            padding: VivrantLayout.pagePadding,
            children: [
              const PageHeader(
                eyebrow: 'Settings',
                title: 'Tune your',
                highlight: 'experience',
              ),
              if (_loadingPrefs)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Text(
                'Appearance, alerts, and when your day starts.',
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
                            color: accent
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
                            icon: Icons.palette_outlined,
                            label: 'Appearance',
                            soft: soft,
                            accent: accent,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('theme-$_theme'),
                            initialValue: _theme,
                            decoration: InputDecoration(
                              labelText: 'Theme',
                              prefixIcon: Icon(
                                Icons.brightness_6_outlined,
                                size: 20,
                                color: muted,
                              ),
                            ),
                            items: _themeOptions
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o.$1,
                                    child: Text(o.$2),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _theme = v);
                              ref
                                  .read(themeModeProvider.notifier)
                                  .setThemeFromPreference(v);
                            },
                          ),
                          const SizedBox(height: 20),
                          _PrefHint(
                            icon: Icons.schedule_rounded,
                            label: 'Timezone',
                            soft: soft,
                            accent: accent,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey('tz-${tzValue ?? _timezone.text}'),
                            initialValue: tzValue,
                            decoration: InputDecoration(
                              labelText: 'Timezone',
                              prefixIcon: Icon(
                                Icons.public_rounded,
                                size: 20,
                                color: muted,
                              ),
                            ),
                            items: _timezoneOptions
                                .map(
                                  (tz) => DropdownMenuItem(
                                    value: tz,
                                    child: Text(tz),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _timezone.text = v);
                            },
                          ),
                          if (tzValue == null) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _timezone,
                              decoration: InputDecoration(
                                labelText: 'Custom IANA timezone',
                                hintText: 'Asia/Manila',
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                  color: muted,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          _PrefHint(
                            icon: Icons.notifications_outlined,
                            label: 'Alerts',
                            soft: soft,
                            accent: accent,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Push notifications',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Alerts for tickets, broadcasts, and insights',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                            value: _notifications,
                            activeThumbColor: accent,
                            onChanged: (v) =>
                                setState(() => _notifications = v),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Weekly report',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Email a summary of your wellbeing trends',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: muted,
                              ),
                            ),
                            value: _weeklyReport,
                            activeThumbColor: accent,
                            onChanged: (v) => setState(() => _weeklyReport = v),
                          ),
                          const SizedBox(height: 12),
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
