import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class GymPlansScreen extends ConsumerStatefulWidget {
  const GymPlansScreen({super.key});

  @override
  ConsumerState<GymPlansScreen> createState() => _GymPlansScreenState();
}

class _GymPlansScreenState extends ConsumerState<GymPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
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
      final plans = await ref.read(vivrantApiProvider).gymPlans();
      if (!mounted) return;
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
      _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                : _plans.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          EmptyState(
                            message: 'No plans yet. Generate one with AI.',
                            action: ElevatedButton(
                              onPressed: _createAi,
                              child: const Text('Create AI plan'),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _plans.length,
                        itemBuilder: (_, i) {
                          final p = _plans[i];
                          final days = p['days_per_week'] ?? p['days'];
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
                                          p['title']?.toString() ?? 'Plan',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          '${p['focus'] ?? 'plan'} · ${days ?? '—'} days/wk',
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
                                            .deleteGymPlan(
                                              (p['id'] as num).toInt(),
                                            );
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
