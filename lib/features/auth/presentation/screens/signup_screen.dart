import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../widgets/social_auth_buttons.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
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
    final muted = Theme.of(context).hintColor;
    return GradientScaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              const PageHeader(
                eyebrow: 'Join VIVRΛNT',
                title: 'Create your',
                highlight: 'space',
              ),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: validateEmail,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: validatePassword,
                onFieldSubmitted: (_) {
                  if (!_loading) _submit();
                },
                decoration: InputDecoration(
                  labelText: 'Password (min 8 chars)',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: muted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
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
      ),
    );
  }
}
