import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../widgets/macro_chips.dart';
import '../widgets/meal_list_tile.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  List<NutritionLog> _meals = [];
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
      final meals = await ref.read(vivrantApiProvider).listMeals();
      if (!mounted) return;
      setState(() {
        _meals = meals;
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
    final totalCal = _meals.fold<double>(0, (s, m) => s + (m.calories ?? 0));
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            PageHeader(
              eyebrow: 'Nutrition',
              title: 'Meals &',
              highlight: 'macros',
              trailing: IconButton(
                onPressed: () => context.push('/nutrition/log'),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ),
            StatCard(
              label: 'Today',
              value: totalCal.toStringAsFixed(0),
              caption: 'kcal logged',
              icon: Icons.restaurant,
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
            else if (_meals.isEmpty)
              EmptyState(
                message: 'No meals yet. Log your first meal.',
                action: ElevatedButton(
                  onPressed: () => context.push('/nutrition/log'),
                  child: const Text('Log meal'),
                ),
              )
            else
              ..._meals.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MealListTile(
                        meal: m,
                        onDelete: () async {
                          await ref.read(vivrantApiProvider).deleteMeal(m.id);
                          _load();
                        },
                      ),
                      if (m.proteinG != null ||
                          m.carbsG != null ||
                          m.fatG != null) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 54),
                          child: MacroChips(
                            proteinG: m.proteinG,
                            carbsG: m.carbsG,
                            fatG: m.fatG,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final ctrl = TextEditingController();
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('AI meal estimate'),
                    content: TextField(
                      controller: ctrl,
                      decoration:
                          const InputDecoration(hintText: 'Describe your meal'),
                      maxLines: 3,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text('Estimate'),
                      ),
                    ],
                  ),
                );
                if (ok == true && ctrl.text.trim().isNotEmpty && mounted) {
                  try {
                    final res = await ref
                        .read(vivrantApiProvider)
                        .estimateMealAi(ctrl.text.trim());
                    if (!mounted) return;
                    context.showInfo(
                      res['summary']?.toString() ?? res.toString(),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    context.showError(apiErrorMessage(e));
                  }
                }
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Estimate meal with AI'),
            ),
          ],
        ),
      ),
    );
  }
}
