import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../shared/providers/auth_provider.dart';

/// Google + GitHub buttons used on login and signup.
class SocialAuthButtons extends ConsumerStatefulWidget {
  const SocialAuthButtons({super.key});

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  OAuthProvider? _pending;

  Future<void> _signIn(OAuthProvider provider) async {
    setState(() => _pending = provider);
    final ok = await ref.read(authProvider.notifier).loginWithOAuth(provider);
    if (!mounted) return;
    setState(() => _pending = null);
    if (!ok) {
      final err = ref.read(authProvider).error;
      context.showError(err ?? 'Social sign-in failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final busy = _pending != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OR CONTINUE WITH',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11.5,
                  letterSpacing: 1.2,
                  color: ink.withValues(alpha: 0.45),
                ),
              ),
            ),
            Expanded(child: Divider(color: ink.withValues(alpha: 0.1))),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                label: 'Google',
                loading: _pending == OAuthProvider.google,
                enabled: !busy,
                onPressed: () => _signIn(OAuthProvider.google),
                icon: Icon(
                  Icons.g_mobiledata_rounded,
                  size: 22,
                  color: dark ? Colors.white : const Color(0xFF4285F4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SocialButton(
                label: 'GitHub',
                loading: _pending == OAuthProvider.github,
                enabled: !busy,
                onPressed: () => _signIn(OAuthProvider.github),
                icon: Icon(
                  Icons.code,
                  size: 18,
                  color: dark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.loading,
    required this.enabled,
  });

  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final bool loading;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: ink.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        foregroundColor: ink,
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
    );
  }
}
