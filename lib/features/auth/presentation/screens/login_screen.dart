import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscure = true;
  String? _formError;
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
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _formError = null;
    });
    final ok = await ref.read(authProvider.notifier).login(
          _email.text.trim(),
          _password.text,
        );
    if (!mounted) return;
    if (ok) {
      setState(() => _loading = false);
      return;
    }
    final err = ref.read(authProvider).error ?? 'Sign in failed';
    setState(() {
      _loading = false;
      _formError = err;
    });
    context.showError(err);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;

    return GradientScaffold(
      child: Stack(
        children: [
          const _AuthAtmosphere(),
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                  children: [
                    const VivrantBrand(),
                    const SizedBox(height: 32),
                    Text(
                      'WELCOME BACK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontSize: 13,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Come back to\n',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              letterSpacing: -0.6,
                            ),
                          ),
                          TextSpan(
                            text: 'yourself',
                            style: GoogleFonts.instrumentSerif(
                              fontSize: 40,
                              fontStyle: FontStyle.italic,
                              height: 1.05,
                              foreground: Paint()
                                ..shader = (dark
                                        ? VivrantColors.darkBrandGradient
                                        : VivrantColors.brandGradient)
                                    .createShader(
                                  const Rect.fromLTWH(0, 0, 240, 54),
                                ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sign in to continue your healthier rhythm — nutrition, movement, sleep, and quiet AI guidance.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Material(
                      color: panel.withValues(alpha: dark ? 0.92 : 0.94),
                      elevation: 0,
                      shadowColor: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                      clipBehavior: Clip.antiAlias,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: ink.withValues(alpha: 0.06),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  accent.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: _email,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  onSubmitted: (_) =>
                                      _passwordFocus.requestFocus(),
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(
                                      Icons.mail_outline_rounded,
                                      size: 22,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _password,
                                  focusNode: _passwordFocus,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) {
                                    if (!_loading) _submit();
                                  },
                                  autofillHints: const [
                                    AutofillHints.password,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Your password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                      size: 22,
                                      color: muted,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: _obscure
                                          ? 'Show password'
                                          : 'Hide password',
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 22,
                                        color: muted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscure = !_obscure,
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 8,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () =>
                                        context.push('/forgot-password'),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_formError != null) ...[
                                  const SizedBox(height: 4),
                                  _LoginErrorBanner(message: _formError!),
                                  const SizedBox(height: 12),
                                ] else
                                  const SizedBox(height: 12),
                                PrimaryButton(
                                  label: 'Sign in',
                                  loading: _loading,
                                  onPressed: _submit,
                                  icon: Icons.arrow_forward_rounded,
                                ),
                                const SizedBox(height: 18),
                                const SocialAuthButtons(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: ink.withValues(alpha: 0.08)),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'BUILT AROUND YOU',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 11.5,
                              letterSpacing: 1.4,
                              color: muted.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: ink.withValues(alpha: 0.08)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _PillGrid(),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here?',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => context.push('/signup'),
                          child: const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Wellness guidance only — not a substitute for professional medical care.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.5,
                        color: muted.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginErrorBanner extends StatelessWidget {
  const _LoginErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFFF97066) : const Color(0xFFB42318);
    final bg = dark ? const Color(0xFF2A1515) : const Color(0xFFFFF1F0);
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillGrid extends StatelessWidget {
  const _PillGrid();

  static const _items = [
    (label: 'Nutrition', icon: Icons.eco_outlined),
    (label: 'Movement', icon: Icons.directions_run_rounded),
    (label: 'Sleep', icon: Icons.nightlight_round),
    (label: 'AI insights', icon: Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Pill(
                    label: _items[row * 2 + col].label,
                    icon: _items[row * 2 + col].icon,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft =
        dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: soft.withValues(alpha: dark ? 0.7 : 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: accent),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft botanical blobs behind the auth form.
class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final c = dark ? VivrantColors.darkCyan : VivrantColors.cyan;

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(
              size: 220,
              color: a.withValues(alpha: dark ? 0.18 : 0.12),
            ),
          ),
          Positioned(
            top: 220,
            left: -100,
            child: _Blob(
              size: 200,
              color: c.withValues(alpha: dark ? 0.14 : 0.08),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -50,
            child: _Blob(
              size: 160,
              color: a.withValues(alpha: dark ? 0.12 : 0.06),
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
