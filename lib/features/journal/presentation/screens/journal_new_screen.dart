import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class JournalNewScreen extends ConsumerStatefulWidget {
  const JournalNewScreen({super.key});

  @override
  ConsumerState<JournalNewScreen> createState() => _JournalNewScreenState();
}

class _JournalNewScreenState extends ConsumerState<JournalNewScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty) {
      context.showError('Write a note first.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(vivrantApiProvider).saveJournal({
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        'body': _body.text.trim(),
      });
      if (!mounted) return;
      context.showSuccess('Journal saved');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('New entry')),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Journal',
            title: 'Write a',
            highlight: 'note',
          ),
          VivrantPanel(
            title: 'Entry',
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _body,
                  decoration: const InputDecoration(labelText: 'Body'),
                  maxLines: 8,
                  autofocus: true,
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _saving ? 'Saving…' : 'Save entry',
                  loading: _saving,
                  onPressed: _save,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
