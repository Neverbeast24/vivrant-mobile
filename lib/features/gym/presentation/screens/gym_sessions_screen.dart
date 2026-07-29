import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class GymSessionsScreen extends ConsumerStatefulWidget {
  const GymSessionsScreen({super.key});

  @override
  ConsumerState<GymSessionsScreen> createState() => _GymSessionsScreenState();
}

class _GymSessionsScreenState extends ConsumerState<GymSessionsScreen> {
  List<GymSession> _items = [];
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
      final items = await ref.read(vivrantApiProvider).gymSessions();
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
        await ref.read(vivrantApiProvider).logGymSession({
          'title': title.text.trim(),
          'focus': 'full_body',
          'duration_minutes': 45,
        });
        _load();
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(onPressed: _log, icon: const Icon(Icons.add)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      EmptyState(
                        message: _error!,
                        action: OutlinedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: const [
                          EmptyState(message: 'No gym sessions yet.'),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final s = _items[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: VivrantPanel(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${s.focus ?? 'session'} · ${s.durationMinutes ?? '—'} min',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
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
                                        _load();
                                      } catch (e) {
                                        if (!mounted) return;
                                        context.showError(apiErrorMessage(e));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
