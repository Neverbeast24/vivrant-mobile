import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/constants/enums.dart';
import '../../../../shared/models/models.dart';

class LogMealScreen extends ConsumerStatefulWidget {
  const LogMealScreen({super.key});

  @override
  ConsumerState<LogMealScreen> createState() => _LogMealScreenState();
}

class _LogMealScreenState extends ConsumerState<LogMealScreen> {
  final _name = TextEditingController();
  final _cal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _type = 'breakfast';
  bool _loading = false;
  List<PantryItem> _pantry = const [];
  List<NutritionLog> _meals = const [];

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    try {
      final api = ref.read(vivrantApiProvider);
      final results = await Future.wait([
        api.listPantry(),
        api.listMeals(),
      ]);
      if (!mounted) return;
      setState(() {
        _pantry = (results[0] as List<PantryItem>)
            .where((p) => p.stockLevel > 0)
            .take(14)
            .toList();
        _meals = results[1] as List<NutritionLog>;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _cal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).logMeal({
        'meal_name': _name.text.trim(),
        'meal_type': _type,
        if (_cal.text.isNotEmpty) 'calories': double.tryParse(_cal.text),
        if (_protein.text.isNotEmpty) 'protein_g': double.tryParse(_protein.text),
        if (_carbs.text.isNotEmpty) 'carbs_g': double.tryParse(_carbs.text),
        if (_fat.text.isNotEmpty) 'fat_g': double.tryParse(_fat.text),
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
      appBar: AppBar(title: const Text('Log meal')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_meals.isNotEmpty || _pantry.isNotEmpty) ...[
            StatCard(
              label: 'Calories today',
              value:
                  '${_meals.fold<double>(0, (s, m) => s + (m.calories ?? 0)).round()}',
              caption:
                  '${_meals.length} meal${_meals.length == 1 ? '' : 's'} · ${2000 - _meals.fold<double>(0, (s, m) => s + (m.calories ?? 0)).round()} left of 2000',
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 12),
          ],
          if (_pantry.isNotEmpty) ...[
            const SectionLabel('Cook from pantry'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _pantry)
                  ActionChip(
                    label: Text(item.name),
                    onPressed: () {
                      _name.text = item.name;
                      setState(() {});
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Meal name'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [
              for (final t in mealTypes)
                DropdownMenuItem(value: t, child: Text(labelForOption(t))),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'snack'),
            decoration: const InputDecoration(labelText: 'Meal type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _protein,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Protein g'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbs,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Carbs g'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fat,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fat g'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save meal'),
          ),
        ],
      ),
    );
  }
}
