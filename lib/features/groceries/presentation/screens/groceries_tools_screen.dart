import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/share_export.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class GroceriesToolsScreen extends ConsumerStatefulWidget {
  const GroceriesToolsScreen({super.key});

  @override
  ConsumerState<GroceriesToolsScreen> createState() =>
      _GroceriesToolsScreenState();
}

class _GroceriesToolsScreenState extends ConsumerState<GroceriesToolsScreen> {
  bool _busy = false;
  int _lowCount = 0;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _loadLow();
  }

  Future<void> _loadLow() async {
    try {
      final pantry = await ref.read(vivrantApiProvider).listPantry();
      if (!mounted) return;
      setState(() => _lowCount = pantry.where((p) => p.isLowStock).length);
    } catch (_) {}
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      context.showSuccess(ok);
      await _loadLow();
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
        title: const Text('List tools'),
        actions: [
          if (_plan != null) ShareExportButton(doc: groceryPlanDoc(_plan!)),
        ],
      ),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Shopping',
            title: 'List',
            highlight: 'tools',
          ),
          Text(
            'Keep the shopping list itself simple. Restock and planning live here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SectionGap(),
          ModuleTile(
            icon: Icons.warning_amber_outlined,
            label: 'Add low stock',
            caption: _lowCount == 0
                ? 'Pantry looks stocked'
                : '$_lowCount low items → shopping list',
            onTap: _busy
                ? () {}
                : () => _run(
                      () => ref.read(vivrantApiProvider).addLowStockToGrocery(),
                      'Low stock added to list',
                    ),
          ),
          const TileGap(),
          ModuleTile(
            icon: Icons.inventory_2_outlined,
            label: 'Clear completed',
            caption: 'Archive checked items',
            onTap: _busy
                ? () {}
                : () async {
                    final ok = await confirmAction(
                      context,
                      title: 'Archive completed items?',
                      body:
                          'Checked groceries will leave this list and move to Archived.',
                      confirmLabel: 'Archive',
                    );
                    if (!ok || !mounted) return;
                    await _run(
                      () => ref
                          .read(vivrantApiProvider)
                          .clearCompletedGroceries(),
                      'Cleared completed',
                    );
                  },
          ),
          const TileGap(),
          ModuleTile(
            icon: Icons.kitchen_outlined,
            label: 'Restock pantry',
            caption: 'Checked items go back on the shelf',
            onTap: _busy
                ? () {}
                : () => _run(
                      () => ref
                          .read(vivrantApiProvider)
                          .restockPantryFromChecked(),
                      'Pantry restocked',
                    ),
          ),
          const TileGap(),
          ModuleTile(
            icon: Icons.auto_awesome,
            label: 'Smart plan',
            caption: 'AI shopping suggestions',
            onTap: _busy
                ? () {}
                : () async {
                    setState(() => _busy = true);
                    try {
                      final res =
                          await ref.read(vivrantApiProvider).smartGroceryPlan();
                      if (!mounted) return;
                      final planRaw = res['plan'];
                      final plan = planRaw is Map
                          ? Map<String, dynamic>.from(planRaw)
                          : Map<String, dynamic>.from(res);
                      setState(() => _plan = plan);
                      if (!mounted) return;
                      final summary = [
                        plan['title']?.toString(),
                        plan['summary']?.toString(),
                      ].where((s) => s != null && s.isNotEmpty).join('\n');
                      context.showInfo(
                        summary.isEmpty
                            ? 'Plan ready. Share it from the button above.'
                            : summary,
                      );
                      if (!mounted) return;
                      await showShareExportSheet(context, groceryPlanDoc(plan));
                    } catch (e) {
                      if (!mounted) return;
                      context.showError(apiErrorMessage(e));
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
          ),
          if (_plan != null) ...[
            const TileGap(),
            ModuleTile(
              icon: Icons.ios_share_rounded,
              label: 'Share last plan',
              caption: _plan!['title']?.toString() ?? 'Grocery plan',
              onTap: () => showShareExportSheet(context, groceryPlanDoc(_plan!)),
            ),
          ],
        ],
      ),
    );
  }
}
