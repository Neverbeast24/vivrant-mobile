import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).changePassword(
            currentPassword: _current.text,
            password: _password.text,
          );
      if (!mounted) return;
      context.showSuccess('Password updated for web and mobile.');
      context.pop();
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

    return GradientScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text('Change password'),
      ),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Security',
            title: 'Update your',
            highlight: 'password',
          ),
          Text(
            'This updates the same password used for email sign-in on web and mobile.',
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
                  color: accent.withValues(alpha: dark ? 0.08 : 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _current,
                    obscureText: _obscureCurrent,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        size: 20,
                        color: muted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Current password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'New password',
                      hintText: 'At least 8 characters',
                      prefixIcon: Icon(
                        Icons.lock_rounded,
                        size: 20,
                        color: muted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscureConfirm,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Confirm new password',
                      prefixIcon: Icon(
                        Icons.lock_rounded,
                        size: 20,
                        color: muted,
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Passwords do not match';
                      }
                      return validatePassword(value);
                    },
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: _loading ? 'Updating…' : 'Update password',
                    loading: _loading,
                    onPressed: _submit,
                    icon: Icons.check_rounded,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
