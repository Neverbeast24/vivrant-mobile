import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key, this.entity});

  final String? entity;

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  bool _loading = true;
  String? _error;
  String _filter = 'all';
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.entity ?? 'all';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(vivrantApiProvider).listActivity(
            entity: widget.entity,
          );
      if (!mounted) return;
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

  List<String> get _entities {
    final values = _items
        .map((item) => item['entity']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _visible {
    if (_filter == 'all') return _items;
    return _items.where((item) => item['entity']?.toString() == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return GradientScaffold(
      appBar: AppBar(title: const Text('Activity')),
      child: AsyncBody(
        loading: _loading,
        error: _error,
        onRetry: _load,
        child: _items.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: EmptyState(
                  title: 'No activity yet',
                  message:
                      'Updates to gym programs, meals, and settings show up here.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  if (_entities.length > 1) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: Text('All · ${_items.length}'),
                          selected: _filter == 'all',
                          onSelected: (_) => setState(() => _filter = 'all'),
                        ),
                        for (final entity in _entities)
                          FilterChip(
                            label: Text(
                              '${entity.replaceAll('_', ' ')} · ${_items.where((item) => item['entity'] == entity).length}',
                            ),
                            selected: _filter == entity,
                            onSelected: (_) => setState(() => _filter = entity),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (visible.isEmpty)
                    const EmptyState(message: 'Nothing in this filter.')
                  else
                    for (final item in visible) ...[
                      VivrantPanel(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            (item['title'] as String?)?.trim().isNotEmpty == true
                                ? item['title'] as String
                                : 'Activity',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            [
                              item['detail'] as String?,
                              item['created_at'] as String?,
                            ].whereType<String>().where((value) => value.trim().isNotEmpty).join('\n'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                ],
              ),
      ),
    );
  }
}
