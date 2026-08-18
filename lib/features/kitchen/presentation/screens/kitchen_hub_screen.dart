import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

String pantryToGroceryCategory(String category) {
  final c = category.toLowerCase();
  if (c == 'vegetables' || c == 'fruits') return 'produce';
  if (c == 'protein' ||
      c == 'dairy' ||
      c == 'grains' ||
      c == 'snacks' ||
      c == 'drinks') {
    return c;
  }
  if (c == 'condiments' || c == 'frozen') return 'pantry';
  return 'other';
}

/// Groceries + pantry living on one checklist (mirrors web Kitchen hub).
class KitchenHubScreen extends ConsumerStatefulWidget {
  const KitchenHubScreen({super.key});

  @override
  ConsumerState<KitchenHubScreen> createState() => _KitchenHubScreenState();
}

class _KitchenHubScreenState extends ConsumerState<KitchenHubScreen> {
  List<GroceryItem> _groceries = const [];
  List<PantryItem> _pantry = const [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

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
      final results = await Future.wait([
        api.listGroceries(),
        api.listPantry(),
      ]);
      if (!mounted) return;
      setState(() {
        _groceries = results[0] as List<GroceryItem>;
        _pantry = results[1] as List<PantryItem>;
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

  List<GroceryItem> get _open =>
      _groceries.where((g) => !g.isChecked).toList(growable: false);

  List<PantryItem> get _low =>
      _pantry.where((p) => p.isLowStock).toList(growable: false);

  Set<String> get _openNames =>
      _open.map((g) => g.name.trim().toLowerCase()).toSet();

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Kitchen'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              eyebrow: 'Kitchen',
              title: 'Shop and',
              highlight: 'stock',
            ),
            Text(
              'Check off shopping to restock the pantry. Low stock goes onto the list.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Open list',
                    value: '${_open.length}',
                    caption: '${_groceries.length} total',
                    icon: Icons.shopping_basket_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatCard(
                    label: 'Low stock',
                    value: '${_low.length}',
                    caption: '${_pantry.length} on shelf',
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            else ...[
              VivrantPanel(
                title: 'Shopping list',
                trailing: TextButton(
                  onPressed: () => context.push('/groceries'),
                  child: const Text('Full list'),
                ),
                child: _open.isEmpty
                    ? const Text('Nothing open. Add low-stock items below.')
                    : Column(
                        children: [
                          for (final item in _open.take(10))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListRow(
                                title: item.name,
                                subtitle: item.quantity,
                                leading: Checkbox(
                                  value: false,
                                  onChanged: _busy
                                      ? null
                                      : (_) => _run(
                                            () => ref
                                                .read(vivrantApiProvider)
                                                .toggleGrocery(item.id, true),
                                          ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              VivrantPanel(
                title: 'Low stock → list',
                trailing: TextButton(
                  onPressed: _busy || _low.isEmpty
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(vivrantApiProvider)
                                .addLowStockToGrocery();
                            if (context.mounted) {
                              context.showSuccess('Low stock added to list');
                            }
                          }),
                  child: const Text('Add all'),
                ),
                child: _low.isEmpty
                    ? const Text('Pantry looks stocked.')
                    : Column(
                        children: [
                          for (final item in _low.take(10))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ListRow(
                                title: item.name,
                                subtitle: _openNames.contains(
                                  item.name.trim().toLowerCase(),
                                )
                                    ? '${item.stockLevel}% · already on list'
                                    : '${item.stockLevel}% · tap to add',
                                leading: Checkbox(
                                  value: _openNames.contains(
                                    item.name.trim().toLowerCase(),
                                  ),
                                  onChanged: _busy ||
                                          _openNames.contains(
                                            item.name.trim().toLowerCase(),
                                          )
                                      ? null
                                      : (_) => _run(() async {
                                            await ref
                                                .read(vivrantApiProvider)
                                                .addGrocery({
                                              'name': item.name,
                                              'category':
                                                  pantryToGroceryCategory(
                                                item.category,
                                              ),
                                              'quantity': '1',
                                            });
                                            if (context.mounted) {
                                              context.showSuccess(
                                                'Added ${item.name}',
                                              );
                                            }
                                          }),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              ModuleTile(
                icon: Icons.shopping_basket_outlined,
                label: 'Shopping',
                caption: 'Full grocery list',
                onTap: () => context.push('/groceries'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.kitchen_outlined,
                label: 'Pantry',
                caption: 'Adjust stock levels',
                onTap: () => context.push('/pantry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
