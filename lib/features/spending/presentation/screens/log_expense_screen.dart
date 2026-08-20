import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/constants/enums.dart';
import '../../../../shared/models/models.dart';

class LogExpenseScreen extends ConsumerStatefulWidget {
  const LogExpenseScreen({super.key});

  @override
  ConsumerState<LogExpenseScreen> createState() => _LogExpenseScreenState();
}

class _LogExpenseScreenState extends ConsumerState<LogExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String _category = 'food';
  bool _loading = false;
  Map<String, dynamic>? _overview;
  List<Expense> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final api = ref.read(vivrantApiProvider);
      final overview = await api.spendingOverview();
      final expenses = await api.listExpenses();
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _recent = expenses.take(6).toList();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      context.showError('Enter a title.');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).addExpense({
        'title': _title.text.trim(),
        'category': _category,
        'amount': double.tryParse(_amount.text) ?? 0,
      });
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Log expense')),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          if (_overview != null) ...[
            StatCard(
              label: 'Left this month',
              value: '₱${(_overview!['remaining'] as num?)?.round() ?? 0}',
              caption:
                  '₱${(_overview!['spent'] as num?)?.round() ?? 0} of ₱${(_overview!['budget'] as num?)?.round() ?? 0}',
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _category,
            items: [
              for (final c in expenseCategories)
                DropdownMenuItem(value: c, child: Text(labelForOption(c))),
            ],
            onChanged: (v) => setState(() => _category = v ?? 'other'),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save expense'),
          ),
          if (_recent.isNotEmpty) ...[
            const SizedBox(height: 20),
            const SectionLabel('Recent expenses'),
            for (final e in _recent)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ListRow(
                  title: e.title,
                  subtitle: e.category,
                  trailing: Text(
                    '₱${e.amount.round()}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
