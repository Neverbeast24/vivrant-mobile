import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.adminAudit);
    if (cached != null) {
      _logs = cached.map((e) => Map<String, dynamic>.from(e)).toList();
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

  List<String> get _entities {
    final values = _logs
        .map((l) => l['entity']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _logs.where((log) {
      final entity = log['entity']?.toString() ?? '';
      if (_filter != 'all' && entity != _filter) return false;
      if (q.isEmpty) return true;
      return (log['action']?.toString().toLowerCase() ?? '').contains(q) ||
          (log['actor_name']?.toString().toLowerCase() ?? '').contains(q) ||
          entity.toLowerCase().contains(q) ||
          (log['entity_id']?.toString().toLowerCase() ?? '').contains(q);
    }).toList();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.adminAudit);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final logs = await ref.read(vivrantApiProvider).adminAuditLogs();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.adminAudit, logs);
      setState(() {
        _logs = logs;
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

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Audit logs')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Admin',
              title: 'Audit',
              highlight: 'trail',
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
            else if (_logs.isEmpty)
              const EmptyState(message: 'No audit events yet.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search audit logs…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _logs.length,
                  ),
                  ..._entities.map(
                    (e) => VivrantFilterOption(
                      value: e,
                      label: _titleCase(e),
                      count: _logs
                          .where((l) => l['entity']?.toString() == e)
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
                      'No logs match these filters. Try All or another search.',
                )
              else
                ..._filtered.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['action']?.toString() ?? 'action',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${log['actor_name'] ?? 'Unknown'} · '
                            '${log['entity'] ?? '—'}${log['entity_id'] != null ? ' #${log['entity_id']}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (log['created_at'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateTime.tryParse(log['created_at'].toString())
                                      ?.toLocal()
                                      .toString() ??
                                  log['created_at'].toString(),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ],
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
