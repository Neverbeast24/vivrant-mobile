import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'general';
  bool _loading = false;

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subject.text.trim().isEmpty || _message.text.trim().isEmpty) {
      context.showInfo('Subject and message are required');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).submitSupportTicket({
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
        'category': _category,
      });
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      context.showSuccess('Ticket submitted');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Support')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            eyebrow: 'Help',
            title: 'Contact',
            highlight: 'support',
          ),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: const [
              DropdownMenuItem(value: 'general', child: Text('General')),
              DropdownMenuItem(value: 'bug', child: Text('Bug')),
              DropdownMenuItem(value: 'billing', child: Text('Billing')),
              DropdownMenuItem(value: 'feature', child: Text('Feature')),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'general'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subject,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'Message'),
            maxLines: 5,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Sending…' : 'Submit ticket'),
          ),
        ],
      ),
    );
  }
}
