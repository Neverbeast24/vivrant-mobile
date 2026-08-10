import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class GymPlansScreen extends ConsumerStatefulWidget {
  const GymPlansScreen({super.key});

  @override
  ConsumerState<GymPlansScreen> createState() => _GymPlansScreenState();
}

class _GymPlansScreenState extends ConsumerState<GymPlansScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.gymPlans);
    if (cached != null) {
      _plans = List<Map<String, dynamic>>.from(cached);
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
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.gymPlans);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final plans = await ref.read(vivrantApiProvider).gymPlans();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymPlans, plans);
      setState(() {
        _plans = plans;
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

  Future<void> _createAi() async {
    try {
      await ref.read(vivrantApiProvider).createAiGymPlan();
      if (!mounted) return;
      context.showSuccess('AI plan created');
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  List<String> get _focuses {
    final values = _plans
        .map((p) => p['focus']?.toString() ?? '')
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _plans.where((p) {
      final focus = p['focus']?.toString() ?? '';
      if (_filter != 'all' && focus != _filter) return false;
      if (q.isEmpty) return true;
      final title = p['title']?.toString().toLowerCase() ?? '';
      return title.contains(q) || focus.toLowerCase().contains(q);
    }).toList();
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(RegExp(r'[_\s]+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Training plans'),
        actions: [
          IconButton(
            onPressed: _createAi,
            icon: const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Gym',
              title: 'Training',
              highlight: 'plans',
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
            else if (_plans.isEmpty)
              EmptyState(
                message: 'No plans yet. Generate one with AI.',
                action: ElevatedButton(
                  onPressed: _createAi,
                  child: const Text('Create AI plan'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search plans…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _plans.length,
                  ),
                  ..._focuses.map(
                    (f) => VivrantFilterOption(
                      value: f,
                      label: _titleCase(f),
                      count: _plans
                          .where((p) => p['focus']?.toString() == f)
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
                      'No plans match these filters. Try All or another search.',
                )
              else
                ...filtered.map((p) {
                  final days = p['days_per_week'] ?? p['days'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['title']?.toString() ?? 'Plan',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${_titleCase(p['focus']?.toString() ?? 'plan')} · ${days ?? '—'} days/wk',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final id = (p['id'] as num).toInt();
                              try {
                                await ref
                                    .read(vivrantApiProvider)
                                    .deleteGymPlan(id);
                                if (!mounted) return;
                                setState(() {
                                  _plans = _plans
                                      .where(
                                        (item) =>
                                            (item['id'] as num).toInt() != id,
                                      )
                                      .toList();
                                });
                                ref
                                    .read(moduleCacheProvider)
                                    .write(ModuleCacheKeys.gymPlans, _plans);
                                context.showSuccess('Plan removed');
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
                }),
            ],
          ],
        ),
      ),
    );
  }
}
