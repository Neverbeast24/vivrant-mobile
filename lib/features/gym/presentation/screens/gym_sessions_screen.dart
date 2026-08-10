import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';
import '../gym_labels.dart';

class GymSessionsScreen extends ConsumerStatefulWidget {
  const GymSessionsScreen({super.key});

  @override
  ConsumerState<GymSessionsScreen> createState() => _GymSessionsScreenState();
}

class _GymSessionsScreenState extends ConsumerState<GymSessionsScreen> {
  final _query = TextEditingController();
  List<GymSession> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<GymSession>>(ModuleCacheKeys.gymSessions);
    if (cached != null) {
      _items = List<GymSession>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.gymSessions);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(vivrantApiProvider).gymSessions();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymSessions, items);
      setState(() {
        _items = items;
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

  Future<void> _log() async {
    final title = TextEditingController(text: 'Gym session');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Log gym session'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        final session = await ref.read(vivrantApiProvider).logGymSession({
          'title': title.text.trim(),
          'focus': 'full_body',
          'duration_minutes': 45,
        });
        if (!mounted) return;
        setState(() {
          _items = [session, ..._items];
          _loading = false;
          _error = null;
        });
        ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymSessions, _items);
        context.showSuccess('Session logged');
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  List<String> get _focuses {
    final values = _items
        .map((s) => s.focus ?? '')
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<GymSession> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _items.where((s) {
      if (_filter != 'all' && (s.focus ?? '') != _filter) return false;
      if (q.isEmpty) return true;
      return s.title.toLowerCase().contains(q) ||
          (s.focus?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(onPressed: _log, icon: const Icon(Icons.add)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Gym',
              title: 'Logged',
              highlight: 'sessions',
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
              const EmptyState(message: 'No gym sessions yet.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search sessions…',
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
                  ..._focuses.map(
                    (f) => VivrantFilterOption(
                      value: f,
                      label: humanizeLabel(f),
                      count: _items.where((s) => s.focus == f).length,
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
                      'No sessions match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${humanizeLabel(s.focus ?? 'session')} · ${s.durationMinutes ?? '—'} min',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await ref
                                    .read(vivrantApiProvider)
                                    .deleteGymSession(s.id);
                                if (!mounted) return;
                                setState(() {
                                  _items = _items
                                      .where((x) => x.id != s.id)
                                      .toList();
                                });
                                ref
                                    .read(moduleCacheProvider)
                                    .write(ModuleCacheKeys.gymSessions, _items);
                                context.showSuccess('Session removed');
                              } catch (e) {
                                if (!mounted) return;
                                context.showError(apiErrorMessage(e));
                              }
                            },
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
