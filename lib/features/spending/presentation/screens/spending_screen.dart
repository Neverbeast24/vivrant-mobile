import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class SpendingScreen extends ConsumerStatefulWidget {
  const SpendingScreen({super.key});

  @override
  ConsumerState<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends ConsumerState<SpendingScreen> {
  Map<String, dynamic>? _overview;
  List<Expense> _expenses = [];
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
      final api = ref.read(vivrantApiProvider);
      final overview = await api.spendingOverview();
      final expenses = await api.listExpenses();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _expenses = expenses;
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
    final spent = (_overview?['spent'] as num?)?.toDouble() ??
        _expenses.fold<double>(0, (s, e) => s + e.amount);
    final budget = (_overview?['budget'] as num?)?.toDouble();
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Spending'),
        actions: [
          IconButton(
            onPressed: () => context.push('/spending/budget'),
            icon: const Icon(Icons.pie_chart_outline),
          ),
          IconButton(
            onPressed: () => context.push('/spending/log'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Money',
              title: 'Health',
              highlight: 'spending',
            ),
            StatCard(
              label: 'Spent',
              value: '₱${spent.toStringAsFixed(0)}',
              caption: budget != null
                  ? 'of ₱${budget.toStringAsFixed(0)} budget'
                  : 'this month',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final res =
                      await ref.read(vivrantApiProvider).coachSpending();
                  if (!mounted) return;
                  context.showInfo(
                    res['advice']?.toString() ?? res.toString(),
                  );
                } catch (e) {
                  if (!mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Spending coach'),
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
            else if (_expenses.isEmpty)
              EmptyState(
                message: 'No expenses yet.',
                action: ElevatedButton(
                  onPressed: () => context.push('/spending/log'),
                  child: const Text('Log expense'),
                ),
              )
            else
              ..._expenses.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${e.category} · ₱${e.amount.toStringAsFixed(0)}',
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
                                  .deleteExpense(e.id);
                              _load();
                            } catch (err) {
                              if (!mounted) return;
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
        ),
      ),
    );
  }
}
