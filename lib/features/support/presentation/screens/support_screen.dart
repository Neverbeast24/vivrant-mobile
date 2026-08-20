import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/humanize.dart';
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
  String _category = 'other';
  bool _loading = false;
  bool _ticketsLoading = true;
  String? _ticketsError;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _ticketsLoading = true;
      _ticketsError = null;
    });
    try {
      final tickets = await ref.read(vivrantApiProvider).listSupportTickets();
      if (!mounted) return;
      setState(() {
        _tickets = tickets;
        _ticketsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ticketsError = apiErrorMessage(e);
        _ticketsLoading = false;
      });
    }
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
        'body': _message.text.trim(),
        'category': _category,
      });
      if (!mounted) return;
      _subject.clear();
      _message.clear();
      context.showSuccess('Ticket submitted');
      await _loadTickets();
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
      child: RefreshIndicator(
        onRefresh: _loadTickets,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Help',
              title: 'Contact',
              highlight: 'support',
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: 'bug', child: Text('Bug')),
                DropdownMenuItem(value: 'feature', child: Text('Feature')),
                DropdownMenuItem(value: 'account', child: Text('Account')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
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
            const SizedBox(height: 28),
            Text(
              'Your tickets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            if (_ticketsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ticketsError != null)
              EmptyState(
                message: _ticketsError!,
                action: OutlinedButton(
                  onPressed: _loadTickets,
                  child: const Text('Retry'),
                ),
              )
            else if (_tickets.isEmpty)
              const EmptyState(
                message:
                    'No tickets yet. Submit one above if something looks off.',
              )
            else
              ..._tickets.map((ticket) {
                final status = ticket['status']?.toString() ?? 'open';
                final subject = ticket['subject']?.toString() ?? 'Ticket';
                final description = ticket['description']?.toString() ??
                    ticket['body']?.toString() ??
                    '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              humanizeLabel(status),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(description),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
