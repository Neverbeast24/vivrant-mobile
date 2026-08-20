import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
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
  final _formKey = GlobalKey<FormState>();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _formError = null;
    });
    final ok = await ref.read(authProvider.notifier).login(
          _email.text.trim().toLowerCase(),
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
      child: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: VivrantBrand(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'WELCOME BACK',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accent,
                        fontSize: 13,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Sign in to\n',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              height: 1.12,
                              letterSpacing: -0.6,
                            ),
                          ),
                          TextSpan(
                            text: 'continue',
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
                    const SizedBox(height: 10),
                    Text(
                      'Track meals, workouts, and sleep in one simple place.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: muted,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 22),
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
                          child: Form(
                            key: _formKey,
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextFormField(
                                    controller: _email,
                                    focusNode: _emailFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.email],
                                    validator: validateEmail,
                                    onFieldSubmitted: (_) =>
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
                                  TextFormField(
                                    controller: _password,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    validator: (v) =>
                                        validatePassword(v, minLength: 1),
                                    onFieldSubmitted: (_) {
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
                    ),
                    const SizedBox(height: 22),
                    const _BuiltAroundYou(),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 10),
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

class _BuiltAroundYou extends StatelessWidget {
  const _BuiltAroundYou();

  static const _items = [
    (
      label: 'Nutrition',
      hint: 'Fuel well',
      icon: Icons.eco_outlined,
    ),
    (
      label: 'Movement',
      hint: 'Stay active',
      icon: Icons.directions_run_rounded,
    ),
    (
      label: 'Sleep',
      hint: 'Rest deep',
      icon: Icons.nightlight_round,
    ),
    (
      label: 'Insights',
      hint: 'AI-guided',
      icon: Icons.auto_awesome_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: panel.withValues(alpha: dark ? 0.72 : 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'BUILT AROUND YOU',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 12,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                  color: muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Food, movement, sleep, and helpful tips — together.',
            style: GoogleFonts.instrumentSerif(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.25,
              color: ink.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _FeatureTile(
                    label: _items[i].label,
                    hint: _items[i].hint,
                    icon: _items[i].icon,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.label,
    required this.hint,
    required this.icon,
  });

  final String label;
  final String hint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft =
        dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            soft.withValues(alpha: dark ? 0.85 : 0.95),
            soft.withValues(alpha: dark ? 0.45 : 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              height: 1.15,
              color: ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: muted,
            ),
          ),
        ],
      ),
    );
  }
}
