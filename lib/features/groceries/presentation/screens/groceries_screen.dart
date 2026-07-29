import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

class GroceriesScreen extends ConsumerStatefulWidget {
  const GroceriesScreen({super.key});

  @override
  ConsumerState<GroceriesScreen> createState() => _GroceriesScreenState();
}

class _GroceriesScreenState extends ConsumerState<GroceriesScreen> {
  final _query = TextEditingController();
  List<GroceryItem> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<GroceryItem>>(ModuleCacheKeys.groceries);
    if (cached != null) {
      _items = List<GroceryItem>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setItems(List<GroceryItem> items) {
    ref.read(moduleCacheProvider).write(ModuleCacheKeys.groceries, items);
    setState(() {
      _items = items;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    final showSpinner = ref
        .read(moduleCacheProvider)
        .shouldShowSpinner(ModuleCacheKeys.groceries);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(vivrantApiProvider).listGroceries();
      if (!mounted) return;
      _setItems(items);
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
    final itemName = name.text.trim();
    final itemQty = qty.text.trim();
    name.dispose();
    qty.dispose();
    if (ok == true && itemName.isNotEmpty && mounted) {
      try {
        final item = await ref.read(vivrantApiProvider).addGrocery({
          'name': itemName,
          if (itemQty.isNotEmpty) 'quantity': itemQty,
        });
        if (!mounted) return;
        _setItems([..._items, item]);
        context.showSuccess('Item added');
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  Future<void> _toggle(GroceryItem item, bool checked) async {
    final prev = List<GroceryItem>.from(_items);
    _setItems([
      for (final i in _items)
        if (i.id == item.id) i.copyWith(isChecked: checked) else i,
    ]);
    try {
      await ref.read(vivrantApiProvider).toggleGrocery(item.id, checked);
      if (!mounted) return;
      context.showSuccess(checked ? 'Item checked' : 'Item unchecked');
    } catch (e) {
      if (!mounted) return;
      _setItems(prev);
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _delete(GroceryItem item) async {
    final prev = List<GroceryItem>.from(_items);
    _setItems(_items.where((i) => i.id != item.id).toList());
    try {
      await ref.read(vivrantApiProvider).deleteGrocery(item.id);
      if (!mounted) return;
      context.showSuccess('Item removed');
    } catch (e) {
      if (!mounted) return;
      _setItems(prev);
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      context.showSuccess(success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  List<GroceryItem> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _items.where((item) {
      if (_filter == 'open' && item.isChecked) return false;
      if (_filter == 'done' && !item.isChecked) return false;
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) ||
          (item.quantity?.toLowerCase().contains(q) ?? false) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final checked = _items.where((i) => i.isChecked).length;
    final filtered = _filtered;
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
                      await _load();
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
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search groceries…',
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
                  VivrantFilterOption(
                    value: 'open',
                    label: 'To buy',
                    count: _items.where((i) => !i.isChecked).length,
                  ),
                  VivrantFilterOption(
                    value: 'done',
                    label: 'Checked',
                    count: checked,
                  ),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No items match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: VivrantPanel(
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isChecked,
                            onChanged: (v) => _toggle(item, v ?? false),
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
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(item),
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
