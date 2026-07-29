import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/social_auth_buttons.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final ok = await ref.read(authProvider.notifier).signup(
          email: _email.text.trim(),
          password: _password.text,
          displayName:
              _name.text.trim().isEmpty ? null : _name.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    final err = ref.read(authProvider).error;
    if (ok) {
      context.showSuccess(err ?? 'Account created.');
      if (err != null) context.go('/login');
    } else {
      context.showError(err ?? 'Signup failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            const PageHeader(
              eyebrow: 'Join VIVRΛNT',
              title: 'Create your',
              highlight: 'space',
            ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Display name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password (min 8 chars)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: Text(_loading ? 'Creating…' : 'Create account'),
            ),
            const SizedBox(height: 20),
            const SocialAuthButtons(),
          ],
        ),
      ),
    );
  }
}
