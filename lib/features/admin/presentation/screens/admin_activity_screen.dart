import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class AdminActivityScreen extends ConsumerStatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  ConsumerState<AdminActivityScreen> createState() =>
      _AdminActivityScreenState();
}

class _AdminActivityScreenState extends ConsumerState<AdminActivityScreen> {
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(vivrantApiProvider).adminActivity(
            memberId: _memberId,
            module: _module,
          );
      if (!mounted) return;
      setState(() {
        _members = (data['members'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _modules = (data['modules'] as List? ?? ['all'])
            .map((e) => e.toString())
            .toList();
        _records = (data['records'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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
            else
              ..._records.map(
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
        ),
      ),
    );
  }
}
