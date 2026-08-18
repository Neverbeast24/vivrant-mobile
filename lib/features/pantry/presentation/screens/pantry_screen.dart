import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/humanize.dart';
import '../../../../core/utils/share_export.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _query = TextEditingController();
  List<PantryItem> _items = [];
  List<GroceryItem> _groceries = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached =
        ref.read(moduleCacheProvider).read<List<PantryItem>>(ModuleCacheKeys.pantry);
    if (cached != null) {
      _items = List<PantryItem>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _setItems(List<PantryItem> items) {
    ref.read(moduleCacheProvider).write(ModuleCacheKeys.pantry, items);
    setState(() {
      _items = items;
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load() async {
    final showSpinner =
        ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.pantry);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(vivrantApiProvider);
      final items = await api.listPantry();
      List<GroceryItem> groceries = const [];
      try {
        groceries = await api.listGroceries();
      } catch (_) {}
      if (!mounted) return;
      _groceries = groceries;
      _setItems(items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  void _patchStock(int id, int stockLevel) {
    _setItems([
      for (final item in _items)
        if (item.id == id) item.copyWith(stockLevel: stockLevel) else item,
    ]);
  }

  Future<void> _commitStock(PantryItem item, int stockLevel) async {
    final prev = item.stockLevel;
    _patchStock(item.id, stockLevel);
    try {
      await ref.read(vivrantApiProvider).updatePantryStock(item.id, stockLevel);
      if (!mounted) return;
      context.showSuccess('Stock updated');
    } catch (e) {
      if (!mounted) return;
      _patchStock(item.id, prev);
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _delete(PantryItem item) async {
    final prev = List<PantryItem>.from(_items);
    _setItems(_items.where((i) => i.id != item.id).toList());
    try {
      await ref.read(vivrantApiProvider).deletePantry(item.id);
      if (!mounted) return;
      context.showSuccess('Item removed');
    } catch (e) {
      if (!mounted) return;
      _setItems(prev);
      context.showError(apiErrorMessage(e));
    }
  }

  List<String> get _categories {
    final cats = _items.map((i) => i.category).where((c) => c.isNotEmpty).toSet().toList()
      ..sort();
    return cats;
  }

  List<VivrantFilterOption<String>> get _filterOptions => [
        VivrantFilterOption(
          value: 'all',
          label: 'All',
          count: _items.length,
        ),
        VivrantFilterOption(
          value: 'low',
          label: 'Low stock',
          count: _items.where((i) => i.isLowStock).length,
        ),
        ..._categories.map(
          (c) => VivrantFilterOption(
            value: 'cat:$c',
            label: humanizeLabel(c),
            count: _items.where((i) => i.category == c).length,
          ),
        ),
      ];

  List<PantryItem> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _items.where((item) {
      if (_filter == 'low' && !item.isLowStock) return false;
      if (_filter.startsWith('cat:') &&
          item.category != _filter.substring(4)) {
        return false;
      }
      if (q.isEmpty) return true;
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final low = _items.where((i) => i.isLowStock).length;
    final filtered = _filtered;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          if (_items.isNotEmpty) ShareExportButton(doc: pantryDoc(_items)),
          IconButton(
            tooltip: 'Add pantry item',
            onPressed: () => context.push('/pantry/add'),
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
              eyebrow: 'Kitchen',
              title: 'Pantry',
              highlight: 'stock',
            ),
            StatCard(
              label: 'Low stock',
              value: '$low',
              caption: 'of ${_items.length} items',
              icon: Icons.kitchen_outlined,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref.read(vivrantApiProvider).addLowStockToGrocery();
                  if (!context.mounted) return;
                  context.showSuccess('Low stock added to groceries');
                  await _load();
                } catch (e) {
                  if (!context.mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Add low stock to groceries'),
            ),
            Builder(builder: (context) {
              final open = _groceries.where((g) => !g.isChecked).toList();
              if (open.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: VivrantPanel(
                  title: 'Shopping list',
                  trailing: TextButton(
                    onPressed: () => context.push('/groceries'),
                    child: const Text('Open'),
                  ),
                  child: Column(
                    children: [
                      for (final item in open.take(8))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListRow(
                            title: item.name,
                            subtitle: item.quantity,
                            leading: Checkbox(
                              value: false,
                              onChanged: (_) async {
                                try {
                                  await ref
                                      .read(vivrantApiProvider)
                                      .toggleGrocery(item.id, true);
                                  if (!context.mounted) return;
                                  context.showSuccess('Checked · pantry restocked');
                                  await _load();
                                } catch (e) {
                                  if (!context.mounted) return;
                                  context.showError(apiErrorMessage(e));
                                }
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
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
                message: 'Pantry is empty.',
                action: ElevatedButton(
                  onPressed: () => context.push('/pantry/add'),
                  child: const Text('Add item'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search pantry…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: _filterOptions,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (item.isLowStock)
                                Text(
                                  'LOW',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: VivrantColors.of(context).accent,
                                      ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _delete(item),
                              ),
                            ],
                          ),
                          Text(
                            '${item.category} · ${item.stockLevel}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Slider(
                            value: item.stockLevel.toDouble().clamp(0, 100),
                            min: 0,
                            max: 100,
                            divisions: 20,
                            label: '${item.stockLevel}%',
                            onChanged: (v) => _patchStock(item.id, v.round()),
                            onChangeEnd: (v) => _commitStock(item, v.round()),
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
