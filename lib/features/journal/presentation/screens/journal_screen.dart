import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _query = TextEditingController();
  List<JournalEntry> _entries = [];
  bool _loading = true;
  String? _error;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<JournalEntry>>(ModuleCacheKeys.journal);
    if (cached != null) {
      _entries = List<JournalEntry>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _setEntries(List<JournalEntry> entries) {
    ref.read(moduleCacheProvider).write(ModuleCacheKeys.journal, entries);
    setState(() {
      _entries = entries;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.journal);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final entries = await ref.read(vivrantApiProvider).listJournal();
      if (!mounted) return;
      _setEntries(entries);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_body.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final entry = await ref.read(vivrantApiProvider).saveJournal({
        if (_title.text.trim().isNotEmpty) 'title': _title.text.trim(),
        'body': _body.text.trim(),
      });
      if (!mounted) return;
      _title.clear();
      _body.clear();
      _setEntries([entry, ..._entries.where((e) => e.id != entry.id)]);
      context.showSuccess('Journal saved');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reflect() async {
    try {
      final res = await ref.read(vivrantApiProvider).reflectJournal();
      if (!mounted) return;
      context.showInfo(
        formatAiResponse(
          res,
          keys: const ['reflection', 'tip', 'insight', 'advice'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  List<JournalEntry> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _entries.where((e) {
      switch (_filter) {
        case 'good':
          if (e.mood == null || e.mood! < 4) return false;
        case 'ok':
          if (e.mood != 3) return false;
        case 'low':
          if (e.mood == null || e.mood! > 2) return false;
        case 'unrated':
          if (e.mood != null) return false;
      }
      if (q.isEmpty) return true;
      return (e.title?.toLowerCase().contains(q) ?? false) ||
          e.body.toLowerCase().contains(q) ||
          e.entryDate.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Journal')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Reflect',
              title: 'Your',
              highlight: 'journal',
            ),
            VivrantPanel(
              title: 'New entry',
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _body,
                    decoration: const InputDecoration(labelText: 'Body'),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save entry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _reflect,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Reflect with AI'),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (_entries.isEmpty)
              const EmptyState(message: 'No journal entries yet.')
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search journal…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _entries.length,
                  ),
                  const VivrantFilterOption(value: 'good', label: 'Good'),
                  const VivrantFilterOption(value: 'ok', label: 'OK'),
                  const VivrantFilterOption(value: 'low', label: 'Low'),
                  const VivrantFilterOption(value: 'unrated', label: 'Unrated'),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No notes match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.title?.isNotEmpty == true
                                      ? e.title!
                                      : e.entryDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final prev = List<JournalEntry>.from(_entries);
                              _setEntries(
                                _entries.where((x) => x.id != e.id).toList(),
                              );
                              try {
                                await ref
                                    .read(vivrantApiProvider)
                                    .deleteJournal(e.id);
                                if (!mounted) return;
                                context.showSuccess('Entry removed');
                              } catch (err) {
                                if (!mounted) return;
                                _setEntries(prev);
                                context.showError(apiErrorMessage(err));
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
