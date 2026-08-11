import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';
import '../../../../shared/providers/shell_tab_provider.dart';
import '../widgets/macro_chips.dart';
import '../widgets/meal_list_tile.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  static const _tabIndex = 1;

  final _query = TextEditingController();
  List<NutritionLog> _meals = [];
  bool _loading = false;
  bool _activated = false;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<NutritionLog>>(ModuleCacheKeys.nutrition);
    if (cached != null) {
      _meals = List<NutritionLog>.from(cached);
      _loading = false;
    }
    // Defer first fetch until this tab is selected (IndexedStack mounts all tabs).
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeActivate());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _maybeActivate() {
    if (!mounted || _activated) return;
    if (ref.read(shellTabIndexProvider) != _tabIndex) return;
    _activated = true;
    _load();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.nutrition);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final meals = await ref.read(vivrantApiProvider).listMeals();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.nutrition, meals);
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
    ref.listen<int>(shellTabIndexProvider, (_, next) {
      if (next == _tabIndex) _maybeActivate();
    });
    final totalCal = _meals.fold<double>(0, (s, m) => s + (m.calories ?? 0));
    final types = _meals
        .map((m) => m.mealType)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = _meals.where((m) {
      if (_filter != 'all' && m.mealType != _filter) return false;
      final q = _query.text.trim().toLowerCase();
      if (q.isEmpty) return true;
      return m.mealName.toLowerCase().contains(q) ||
          m.mealType.toLowerCase().contains(q);
    }).toList();

    String titleCase(String value) {
      if (value.isEmpty) return value;
      return value
          .split(RegExp(r'[_\s]+'))
          .map((w) =>
              w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
    }

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
                tooltip: 'Log meal',
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
            if (!_activated || _loading)
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
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search meals…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _meals.length,
                  ),
                  ...types.map(
                    (t) => VivrantFilterOption(
                      value: t,
                      label: titleCase(t),
                      count: _meals.where((m) => m.mealType == t).length,
                    ),
                  ),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No meals match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MealListTile(
                          meal: m,
                          onDelete: () async {
                            try {
                              await ref
                                  .read(vivrantApiProvider)
                                  .deleteMeal(m.id);
                              if (!mounted) return;
                              setState(() {
                                _meals =
                                    _meals.where((x) => x.id != m.id).toList();
                              });
                              ref
                                  .read(moduleCacheProvider)
                                  .write(ModuleCacheKeys.nutrition, _meals);
                              context.showSuccess('Meal removed');
                            } catch (e) {
                              if (!mounted) return;
                              context.showError(apiErrorMessage(e));
                            }
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
            ],
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _estimateMeal(),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Estimate meal with AI'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _suggestMealAi,
              icon: const Icon(Icons.restaurant_outlined),
              label: const Text('Suggest meal with AI'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _suggestMealAi() async {
    try {
      final res = await ref.read(vivrantApiProvider).suggestMealAi();
      if (!mounted) return;
      context.showInfo(
        formatAiResponse(
          res,
          keys: const ['suggestion', 'advice', 'tip', 'reason'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _estimateMeal() async {
    final ctrl = TextEditingController();
    String? photoPath;
    String? photoName;

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('AI meal estimate'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(
                      hintText: 'Describe your meal (optional with photo)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final source = await showModalBottomSheet<ImageSource>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheetCtx) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading:
                                    const Icon(Icons.photo_library_outlined),
                                title: const Text('Gallery'),
                                onTap: () => Navigator.pop(
                                  sheetCtx,
                                  ImageSource.gallery,
                                ),
                              ),
                              ListTile(
                                leading:
                                    const Icon(Icons.photo_camera_outlined),
                                title: const Text('Camera'),
                                onTap: () => Navigator.pop(
                                  sheetCtx,
                                  ImageSource.camera,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (source == null) return;
                      final file = await ImagePicker().pickImage(
                        source: source,
                        maxWidth: 1280,
                        maxHeight: 1280,
                        imageQuality: 85,
                      );
                      if (file == null) return;
                      setLocal(() {
                        photoPath = file.path;
                        photoName = file.name;
                      });
                    },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      photoName == null ? 'Add meal photo' : photoName!,
                    ),
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
                  child: const Text('Estimate'),
                ),
              ],
            );
          },
        );
      },
    );

    final description = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true || !mounted) return;
    if (description.length < 2 && photoPath == null) {
      context.showError('Describe the meal or attach a photo first.');
      return;
    }

    try {
      final res = await ref.read(vivrantApiProvider).estimateMealAi(
            description,
            photoPath: photoPath,
          );
      if (!mounted) return;
      final name = res['meal_name']?.toString();
      final summary = res['summary']?.toString() ?? res.toString();
      final macros = [
        if (res['calories'] != null) '${res['calories']} kcal',
        if (res['protein_g'] != null) 'P ${res['protein_g']}g',
        if (res['carbs_g'] != null) 'C ${res['carbs_g']}g',
        if (res['fat_g'] != null) 'F ${res['fat_g']}g',
      ].join(' · ');
      context.showInfo(
        [
          if (name != null && name.isNotEmpty) name,
          if (macros.isNotEmpty) macros,
          summary,
        ].where((s) => s.isNotEmpty).join('\n'),
      );
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }
}
