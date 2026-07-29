import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class AdminTicketsScreen extends ConsumerStatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  ConsumerState<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends ConsumerState<AdminTicketsScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.adminTickets);
    if (cached != null) {
      _tickets = cached
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  List<String> get _statuses {
    final values = _tickets
        .map((t) => t['status']?.toString() ?? 'open')
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _tickets.where((ticket) {
      final status = ticket['status']?.toString() ?? 'open';
      if (_filter != 'all' && status != _filter) return false;
      if (q.isEmpty) return true;
      return (ticket['subject']?.toString().toLowerCase() ?? '').contains(q) ||
          (ticket['description']?.toString().toLowerCase() ?? '').contains(q) ||
          (ticket['display_name']?.toString().toLowerCase() ?? '').contains(q) ||
          status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.adminTickets);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final tickets = await ref.read(vivrantApiProvider).adminTickets();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.adminTickets, tickets);
      setState(() {
        _tickets = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _edit(Map<String, dynamic> ticket) async {
    var status = ticket['status']?.toString() ?? 'open';
    final note = TextEditingController(
      text: ticket['admin_note']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ticket['subject']?.toString() ?? 'Ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Open')),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Text('In progress'),
                ),
                DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                DropdownMenuItem(value: 'closed', child: Text('Closed')),
              ],
              onChanged: (v) => status = v ?? status,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Staff note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(vivrantApiProvider).adminUpdateTicket({
        'id': ticket['id'],
        'status': status,
        'admin_note': note.text.trim().isEmpty ? null : note.text.trim(),
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      note.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Tickets')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Admin',
              title: 'Support',
              highlight: 'tickets',
            ),
            if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (_loading)
              const LoadingView()
            else if (_tickets.isEmpty)
              const EmptyState(message: 'No tickets yet.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search tickets…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _tickets.length,
                  ),
                  ..._statuses.map(
                    (s) => VivrantFilterOption(
                      value: s,
                      label: _titleCase(s),
                      count: _tickets
                          .where(
                            (t) => (t['status']?.toString() ?? 'open') == s,
                          )
                          .length,
                    ),
                  ),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (_filtered.isEmpty)
                const EmptyState(
                  message:
                      'No tickets match these filters. Try All or another search.',
                )
              else
                ..._filtered.map(
                  (ticket) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: InkWell(
                        onTap: () => _edit(ticket),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket['subject']?.toString() ?? 'Ticket',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '#${ticket['id']} · ${ticket['display_name'] ?? 'Member'} · '
                              '${ticket['status'] ?? 'open'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(ticket['description']?.toString() ?? ''),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
