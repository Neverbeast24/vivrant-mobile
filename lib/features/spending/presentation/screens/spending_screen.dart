import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

/// Spending hub — destinations only. The expense list is on history.
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
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.spending);
    if (cached != null) {
      _overview = cached['overview'] as Map<String, dynamic>?;
      final expenses = cached['expenses'];
      if (expenses is List<Expense>) {
        _expenses = List<Expense>.from(expenses);
      }
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final showSpinner =
        ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.spending);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(vivrantApiProvider);
      final results = await Future.wait([
        api.spendingOverview(),
        api.listExpenses(),
      ]);
      if (!mounted) return;
      final overview = results[0] as Map<String, dynamic>;
      final expenses = results[1] as List<Expense>;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.spending, {
        'overview': overview,
        'expenses': expenses,
      });
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
      appBar: AppBar(title: const Text('Spending')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Money',
              title: 'Health',
              highlight: 'spending',
            ),
            if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else
              StatCard(
                label: 'Spent',
                value: _loading && _expenses.isEmpty
                    ? '—'
                    : '₱${spent.toStringAsFixed(0)}',
                caption: budget != null
                    ? 'of ₱${budget.toStringAsFixed(0)} budget'
                    : 'this month',
                icon: Icons.account_balance_wallet_outlined,
              ),
            const SectionGap(),
            const SectionLabel('Log'),
            ModuleTile(
              icon: Icons.add_circle_outline,
              label: 'Log expense',
              caption: 'Add a purchase',
              onTap: () => context.push('/spending/log'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.receipt_long_outlined,
              label: 'Expense history',
              caption: _expenses.isEmpty
                  ? 'Past purchases'
                  : '${_expenses.length} this period',
              onTap: () => context.push('/spending/history'),
            ),
            const SectionGap(),
            const SectionLabel('Tools'),
            ModuleTile(
              icon: Icons.table_chart_outlined,
              label: 'Excel sheet',
              caption: 'Edit as a table',
              onTap: () => context.push('/spending/sheet'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.pie_chart_outline,
              label: 'Budget',
              caption: 'Monthly health budget',
              onTap: () => context.push('/spending/budget'),
            ),
            const TileGap(),
            ModuleTile(
              icon: Icons.auto_awesome,
              label: 'Spending coach',
              caption: 'AI notes on this month',
              onTap: () async {
                try {
                  final res = await ref.read(vivrantApiProvider).coachSpending();
                  if (!context.mounted) return;
                  context.showInfo(
                    formatAiResponse(
                      res,
                      keys: const ['advice', 'tip', 'suggestion'],
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
