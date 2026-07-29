import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  List<PantryItem> _items = [];
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
      final items = await ref.read(vivrantApiProvider).listPantry();
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

  @override
  Widget build(BuildContext context) {
    final low = _items.where((i) => i.isLowStock).length;
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Pantry'),
        actions: [
          IconButton(
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
                  if (!mounted) return;
                  context.showSuccess('Low stock added to groceries');
                } catch (e) {
                  if (!mounted) return;
                  context.showError(apiErrorMessage(e));
                }
              },
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Add low stock to groceries'),
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
                message: 'Pantry is empty.',
                action: ElevatedButton(
                  onPressed: () => context.push('/pantry/add'),
                  child: const Text('Add item'),
                ),
              )
            else
              ..._items.map(
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
                                    ?.copyWith(color: VivrantColors.accent),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(vivrantApiProvider)
                                      .deletePantry(item.id);
                                  _load();
                                } catch (e) {
                                  if (!mounted) return;
                                  context.showError(apiErrorMessage(e));
                                }
                              },
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
                          onChanged: (v) async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .updatePantryStock(item.id, v.round());
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
