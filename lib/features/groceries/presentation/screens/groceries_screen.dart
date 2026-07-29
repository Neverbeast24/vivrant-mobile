import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class GroceriesScreen extends ConsumerStatefulWidget {
  const GroceriesScreen({super.key});

  @override
  ConsumerState<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends ConsumerState<GroceriesScreen> {
  List<GroceryItem> _items = [];
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
      final items = await ref.read(vivrantApiProvider).listGroceries();
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

  Future<void> _add() async {
    final name = TextEditingController();
    final qty = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: qty,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty && mounted) {
      try {
        await ref.read(vivrantApiProvider).addGrocery({
          'name': name.text.trim(),
          if (qty.text.trim().isNotEmpty) 'quantity': qty.text.trim(),
        });
        _load();
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      context.showSuccess(success);
      _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final checked = _items.where((i) => i.isChecked).length;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Groceries'),
        actions: [
          IconButton(onPressed: _add, icon: const Icon(Icons.add)),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Shopping',
              title: 'Grocery',
              highlight: 'list',
            ),
            StatCard(
              label: 'Checked',
              value: '$checked / ${_items.length}',
              caption: 'items',
              icon: Icons.shopping_basket_outlined,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Clear completed'),
                  onPressed: () => _run(
                    () => ref
                        .read(vivrantApiProvider)
                        .clearCompletedGroceries(),
                    'Cleared completed',
                  ),
                ),
                ActionChip(
                  label: const Text('Restock pantry'),
                  onPressed: () => _run(
                    () => ref
                        .read(vivrantApiProvider)
                        .restockPantryFromChecked(),
                    'Pantry restocked',
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Smart plan'),
                  onPressed: () async {
                    try {
                      final res =
                          await ref.read(vivrantApiProvider).smartGroceryPlan();
                      if (!mounted) return;
                      context.showInfo(
                        res['summary']?.toString() ?? res.toString(),
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
            else if (_items.isEmpty)
              EmptyState(
                message: 'List is empty.',
                action: ElevatedButton(
                  onPressed: _add,
                  child: const Text('Add item'),
                ),
              )
            else
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isChecked,
                          onChanged: (v) async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .toggleGrocery(item.id, v ?? false);
                              _load();
                            } catch (e) {
                              if (!mounted) return;
                              context.showError(apiErrorMessage(e));
                            }
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.quantity != null)
                                Text(
                                  item.quantity!,
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
                                  .deleteGrocery(item.id);
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
