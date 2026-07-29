import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class AdminInquiriesScreen extends ConsumerStatefulWidget {
  const AdminInquiriesScreen({super.key});

  @override
  ConsumerState<AdminInquiriesScreen> createState() =>
      _AdminInquiriesScreenState();
}

class _AdminInquiriesScreenState extends ConsumerState<AdminInquiriesScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _inquiries = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.adminInquiries);
    if (cached != null) {
      _inquiries = cached
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
    final values = _inquiries
        .map((i) => i['status']?.toString() ?? 'open')
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _inquiries.where((row) {
      final status = row['status']?.toString() ?? 'open';
      if (_filter != 'all' && status != _filter) return false;
      if (q.isEmpty) return true;
      return (row['name']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['email']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['message']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['plan']?.toString().toLowerCase() ?? '').contains(q) ||
          status.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.adminInquiries);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final inquiries = await ref.read(vivrantApiProvider).adminInquiries();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.adminInquiries, inquiries);
      setState(() {
        _inquiries = inquiries;
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

  Future<void> _edit(Map<String, dynamic> inquiry) async {
    var status = inquiry['status']?.toString() ?? 'open';
    final note = TextEditingController(
      text: inquiry['admin_note']?.toString() ?? '',
    );
    final price = TextEditingController(
      text: inquiry['quoted_price']?.toString() ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(inquiry['name']?.toString() ?? 'Inquiry'),
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
              controller: price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quoted price (₱)'),
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
      await ref.read(vivrantApiProvider).adminUpdateInquiry({
        'id': inquiry['id'],
        'status': status,
        'admin_note': note.text.trim().isEmpty ? null : note.text.trim(),
        'quoted_price': double.tryParse(price.text.trim()),
        'send_price_email': false,
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      note.dispose();
      price.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Inquiries')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Super Admin',
              title: 'Contact',
              highlight: 'inquiries',
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
            else if (_inquiries.isEmpty)
              const EmptyState(message: 'No inquiries yet.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search inquiries…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _inquiries.length,
                  ),
                  ..._statuses.map(
                    (s) => VivrantFilterOption(
                      value: s,
                      label: _titleCase(s),
                      count: _inquiries
                          .where(
                            (i) => (i['status']?.toString() ?? 'open') == s,
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
                      'No inquiries match these filters. Try All or another search.',
                )
              else
                ..._filtered.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: InkWell(
                        onTap: () => _edit(row),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row['name']?.toString() ?? 'Inquiry',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${row['email'] ?? '—'} · ${row['plan'] ?? 'general'} · '
                              '${row['status'] ?? 'open'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (row['message'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                row['message'].toString(),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
