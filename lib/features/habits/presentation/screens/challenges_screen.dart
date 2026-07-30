import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/humanize.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.challenges);
    if (cached != null) {
      _items = List<Map<String, dynamic>>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setItems(List<Map<String, dynamic>> items) {
    ref.read(moduleCacheProvider).write(ModuleCacheKeys.challenges, items);
    setState(() {
      _items = items;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.challenges);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(vivrantApiProvider).listChallenges();
      if (!mounted) return;
      _setItems(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final title = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New challenge'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    final text = title.text.trim();
    title.dispose();
    if (ok == true && text.isNotEmpty && mounted) {
      try {
        final challenge = await ref.read(vivrantApiProvider).createChallenge({
          'title': text,
          'target_value': 7,
          'metric': 'habits',
        });
        if (!mounted) return;
        _setItems([challenge, ..._items]);
        context.showSuccess('Challenge created');
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  List<String> get _statuses {
    final values = _items
        .map((c) => c['status']?.toString() ?? 'active')
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _items.where((c) {
      final status = c['status']?.toString() ?? 'active';
      if (_filter != 'all' && status != _filter) return false;
      if (q.isEmpty) return true;
      return (c['title']?.toString().toLowerCase() ?? '').contains(q) ||
          status.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Challenges'),
        actions: [
          IconButton(onPressed: _create, icon: const Icon(Icons.add)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Habits',
              title: 'Active',
              highlight: 'challenges',
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (_items.isEmpty)
              EmptyState(
                message: 'No challenges yet.',
                action: ElevatedButton(
                  onPressed: _create,
                  child: const Text('Create challenge'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search challenges…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _items.length,
                  ),
                  ..._statuses.map(
                    (s) => VivrantFilterOption(
                      value: s,
                      label: humanizeLabel(s),
                      count: _items
                          .where(
                            (c) => (c['status']?.toString() ?? 'active') == s,
                          )
                          .length,
                    ),
                  ),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No challenges match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['title']?.toString() ?? 'Challenge',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${c['duration_days'] ?? '—'} days · ${c['status'] ?? 'active'}',
                            style: Theme.of(context).textTheme.bodySmall,
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
