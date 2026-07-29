import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();
  bool _loading = false;
  bool _initialized = false;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _name.dispose();
    _bio.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _syncControllers(Profile? profile) {
    if (_initialized || profile == null) return;
    _name.text = profile.displayName;
    _bio.text = profile.bio ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).updateProfile({
        'display_name': _name.text.trim(),
        'bio': _bio.text.trim(),
      });
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.showSuccess('Profile updated');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    _syncControllers(profile);

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;
    final displayName = profile?.displayName ?? _name.text;
    final email = profile?.email ?? '';

    return GradientScaffold(
      appBar: AppBar(title: const Text('Profile')),
      child: Stack(
        children: [
          const _ProfileAtmosphere(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _reveal(
                start: 0.0,
                finish: 0.45,
                child: PageHeader(
                  eyebrow: 'You',
                  title: 'Your',
                  highlight: 'profile',
                  trailing: _AvatarBadge(
                    initials: _initials(displayName),
                    avatarUrl: profile?.avatarUrl,
                  ),
                ),
              ),
              if (email.isNotEmpty)
                _reveal(
                  start: 0.08,
                  finish: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 14, color: muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _reveal(
                start: 0.12,
                finish: 0.58,
                child: _SoftCard(
                  color: panel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'About you',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How you show up across Vivrant.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _name,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _bioFocus.requestFocus(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Display name',
                          hintText: 'Your name',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bio,
                        focusNode: _bioFocus,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          hintText: 'A short note about you',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 42),
                            child: Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: _loading ? 'Saving…' : 'Save profile',
                        loading: _loading,
                        onPressed: _save,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _reveal(
                start: 0.28,
                finish: 0.72,
                child: SectionLabel('More'),
              ),
              _reveal(
                start: 0.32,
                finish: 0.78,
                child: _SoftCard(
                  color: panel,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _NavRow(
                        icon: Icons.flag_outlined,
                        title: 'Goals',
                        subtitle: 'Targets you are working toward',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/goals'),
                      ),
                      _Divider(color: ink),
                      _NavRow(
                        icon: Icons.history_rounded,
                        title: 'Health history',
                        subtitle: 'Notes and past records',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/history'),
                      ),
                      _Divider(color: ink),
                      _NavRow(
                        icon: Icons.tune_rounded,
                        title: 'Preferences',
                        subtitle: 'Steps, water, and daily defaults',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/preferences'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _reveal(
                start: 0.48,
                finish: 0.92,
                child: _LogoutButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.initials, this.avatarUrl});

  final String initials;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: VivrantColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: VivrantColors.accent.withValues(alpha: dark ? 0.28 : 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? VivrantColors.darkPanel : Colors.white,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.network(
                avatarUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _Initials(initials: initials),
              )
            : _Initials(initials: initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: VivrantColors.accentDeep,
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: VivrantColors.accent.withValues(alpha: dark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? VivrantColors.darkMuted
        : VivrantColors.muted;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.soft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 12.5,
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  offset: _pressed ? const Offset(0.12, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: color.withValues(alpha: 0.06)),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: panel.withValues(alpha: dark ? 0.7 : 0.85),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ink.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 18, color: ink),
                const SizedBox(width: 8),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAtmosphere extends StatelessWidget {
  const _ProfileAtmosphere();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final c = dark ? VivrantColors.darkCyan : VivrantColors.cyan;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -70,
            child: _Blob(
              size: 200,
              color: a.withValues(alpha: dark ? 0.16 : 0.1),
            ),
          ),
          Positioned(
            top: 280,
            left: -90,
            child: _Blob(
              size: 180,
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
