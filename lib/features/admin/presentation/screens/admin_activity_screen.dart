import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class AdminActivityScreen extends ConsumerStatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  ConsumerState<AdminActivityScreen> createState() =>
      _AdminActivityScreenState();
}

class _AdminActivityScreenState extends ConsumerState<AdminActivityScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _members = [];
  List<String> _modules = const ['all'];
  List<Map<String, dynamic>> _records = [];
  String _memberId = 'all';
  String _module = 'all';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.adminActivity);
    if (cached != null) {
      final members = cached['members'];
      if (members is List) {
        _members = members
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      final modules = cached['modules'];
      if (modules is List) {
        _modules = modules.map((e) => e.toString()).toList();
      }
      final records = cached['records'];
      if (records is List) {
        _records = records
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return _records;
    return _records.where((row) {
      return (row['title']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['detail']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['module']?.toString().toLowerCase() ?? '').contains(q) ||
          (row['value']?.toString().toLowerCase() ?? '').contains(q);
    }).toList();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.adminActivity);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(vivrantApiProvider).adminActivity(
            memberId: _memberId,
            module: _module,
          );
      if (!mounted) return;
      final members = (data['members'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final modules = (data['modules'] as List? ?? ['all'])
          .map((e) => e.toString())
          .toList();
      final records = (data['records'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.adminActivity, {
        'members': members,
        'modules': modules,
        'records': records,
      });
      setState(() {
        _members = members;
        _modules = modules;
        _records = records;
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
      appBar: AppBar(title: const Text('Member activity')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Super Admin',
              title: 'Activity',
              highlight: 'explorer',
            ),
            DropdownButtonFormField<String>(
              initialValue: _memberId,
              decoration: const InputDecoration(labelText: 'Member'),
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All members')),
                ..._members.map(
                  (m) => DropdownMenuItem(
                    value: m['user_id']?.toString() ?? '',
                    child: Text(m['display_name']?.toString() ?? 'Member'),
                  ),
                ),
              ],
              onChanged: (v) {
                setState(() => _memberId = v ?? 'all');
                _load();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _module,
              decoration: const InputDecoration(labelText: 'Module panel'),
              items: _modules
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(m == 'all' ? 'All modules' : m),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _module = v ?? 'all');
                _load();
              },
            ),
            const SizedBox(height: 20),
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
            else if (_records.isEmpty)
              const EmptyState(message: 'No activity matches these filters.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search activity…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (_filtered.isEmpty)
                const EmptyState(
                  message:
                      'No activity matches this search. Try another query.',
                )
              else
                ..._filtered.map(
                  (row) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row['title']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${row['module']} · ${row['value']}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row['detail']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
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
