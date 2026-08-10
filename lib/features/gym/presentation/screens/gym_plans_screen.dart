import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/gym_exercise.dart';
import '../../../../shared/providers/module_cache.dart';
import '../gym_labels.dart';
import '../widgets/exercise_demo_sheet.dart';

class GymPlansScreen extends ConsumerStatefulWidget {
  const GymPlansScreen({super.key});

  @override
  ConsumerState<GymPlansScreen> createState() => _GymPlansScreenState();
}

class _GymPlansScreenState extends ConsumerState<GymPlansScreen> {
  static const _prefsDaysKey = 'vivrant.gym.plan.days';
  static const _prefsSessionKey = 'vivrant.gym.plan.session';
  static const _prefsKnownKey = 'vivrant.gym.knownMachines';
  static const _prefsCustomKey = 'vivrant.gym.knownCustom';
  static const _prefsAvoidKey = 'vivrant.gym.avoidTargets';

  final _query = TextEditingController();
  final _customCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '3');
  final _sessionCtrl = TextEditingController(text: '45');

  List<Map<String, dynamic>> _plans = [];
  List<GymExercise> _exercises = const [];
  final Set<String> _knownSlugs = {};
  final List<String> _customExercises = [];
  final Set<String> _avoidTargets = {};
  final Set<int> _expanded = {};

  bool _loading = true;
  bool _generating = false;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.gymPlans);
    if (cached != null) {
      _plans = List<Map<String, dynamic>>.from(cached);
      _loading = false;
    }
    _restorePrefs();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _customCtrl.dispose();
    _daysCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _daysCtrl.text = prefs.getString(_prefsDaysKey) ?? _daysCtrl.text;
      _sessionCtrl.text = prefs.getString(_prefsSessionKey) ?? _sessionCtrl.text;
      _knownSlugs
        ..clear()
        ..addAll(prefs.getStringList(_prefsKnownKey) ?? const []);
      _customExercises
        ..clear()
        ..addAll(prefs.getStringList(_prefsCustomKey) ?? const []);
      _avoidTargets
        ..clear()
        ..addAll(prefs.getStringList(_prefsAvoidKey) ?? const []);
    });
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsDaysKey, _daysCtrl.text.trim());
    await prefs.setString(_prefsSessionKey, _sessionCtrl.text.trim());
    await prefs.setStringList(_prefsKnownKey, _knownSlugs.toList());
    await prefs.setStringList(_prefsCustomKey, List<String>.from(_customExercises));
    await prefs.setStringList(_prefsAvoidKey, _avoidTargets.toList());
  }

  Future<void> _load() async {
    final showSpinner =
        ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.gymPlans);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(vivrantApiProvider);
      final plans = await api.gymPlans();
      final exerciseRows = await api.gymExercises();
      if (!mounted) return;
      final exercises = exerciseRows.map(GymExercise.fromJson).toList(growable: false);
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.gymPlans, plans);
      setState(() {
        _plans = plans;
        _exercises = exercises;
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

  int get _daysPerWeek {
    final n = int.tryParse(_daysCtrl.text.trim()) ?? 3;
    return n.clamp(2, 6);
  }

  int get _sessionMinutes {
    final n = int.tryParse(_sessionCtrl.text.trim()) ?? 45;
    return n.clamp(15, 120);
  }

  Future<void> _createAi() async {
    setState(() => _generating = true);
    try {
      await _persistPrefs();
      await ref.read(vivrantApiProvider).createAiGymPlan(
            daysPerWeek: _daysPerWeek,
            sessionMinutes: _sessionMinutes,
            knownMachineSlugs: _knownSlugs.toList(),
            knownCustomExercises: List<String>.from(_customExercises),
            avoidTargets: _avoidTargets.toList(),
          );
      if (!mounted) return;
      context.showSuccess('AI plan created');
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _addCustom() {
    final name = _customCtrl.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (name.length < 2) return;
    final exists = _customExercises.any((e) => e.toLowerCase() == name.toLowerCase());
    if (exists) {
      _customCtrl.clear();
      return;
    }
    setState(() {
      _customExercises.add(name);
      _customCtrl.clear();
    });
    _persistPrefs();
  }

  List<String> get _focuses {
    final values = _plans
        .map((p) => p['focus']?.toString() ?? '')
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _plans.where((p) {
      final focus = p['focus']?.toString() ?? '';
      if (_filter != 'all' && focus != _filter) return false;
      if (q.isEmpty) return true;
      final title = p['title']?.toString().toLowerCase() ?? '';
      return title.contains(q) || focus.toLowerCase().contains(q);
    }).toList();
  }

  List<GymExercise> get _machines =>
      _exercises.where((e) => e.isMachine).toList(growable: false);

  List<GymExercise> get _freeWeights =>
      _exercises.where((e) => !e.isMachine).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Training plans'),
        actions: [
          IconButton(
            onPressed: _generating ? null : _createAi,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Gym',
              title: 'Training',
              highlight: 'plans',
            ),
            VivrantPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI plan prefs',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Synced with web: days, session length, avoid targets, known exercises, and custom moves.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _daysCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Days / week',
                            helperText: '2–6',
                          ),
                          onChanged: (_) => _persistPrefs(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _sessionCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Session (min)',
                            helperText: '15–120',
                          ),
                          onChanged: (_) => _persistPrefs(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Avoid targeting',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final target in gymAvoidTargets)
                        FilterChip(
                          label: Text(humanizeLabel(target)),
                          selected: _avoidTargets.contains(target),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _avoidTargets.add(target);
                              } else {
                                _avoidTargets.remove(target);
                              }
                            });
                            _persistPrefs();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Exercises you know',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_knownSlugs.length + _customExercises.length} selected · includes stiff-leg deadlift under free weights',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  _ExerciseChecklist(
                    title: 'Machines',
                    exercises: _machines,
                    selected: _knownSlugs,
                    onToggle: (slug) {
                      setState(() {
                        if (_knownSlugs.contains(slug)) {
                          _knownSlugs.remove(slug);
                        } else {
                          _knownSlugs.add(slug);
                        }
                      });
                      _persistPrefs();
                    },
                    onDemo: (ex) => showExerciseDemoSheet(context, ex),
                  ),
                  const SizedBox(height: 10),
                  _ExerciseChecklist(
                    title: 'Free weights & bodyweight',
                    exercises: _freeWeights,
                    selected: _knownSlugs,
                    onToggle: (slug) {
                      setState(() {
                        if (_knownSlugs.contains(slug)) {
                          _knownSlugs.remove(slug);
                        } else {
                          _knownSlugs.add(slug);
                        }
                      });
                      _persistPrefs();
                    },
                    onDemo: (ex) => showExerciseDemoSheet(context, ex),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Other',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customCtrl,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Hip thrust, landmine press…',
                          ),
                          onSubmitted: (_) => _addCustom(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _addCustom,
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                  if (_customExercises.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final name in _customExercises)
                          InputChip(
                            label: Text(name),
                            onDeleted: () {
                              setState(() => _customExercises.remove(name));
                              _persistPrefs();
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _createAi,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(_generating ? 'Building plan…' : 'Generate AI plan'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
            else if (_plans.isEmpty)
              EmptyState(
                message: 'No plans yet. Set prefs above and generate one with AI.',
                action: ElevatedButton(
                  onPressed: _generating ? null : _createAi,
                  child: const Text('Create AI plan'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search plans…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _plans.length,
                  ),
                  ..._focuses.map(
                    (f) => VivrantFilterOption(
                      value: f,
                      label: humanizeLabel(f),
                      count: _plans
                          .where((p) => p['focus']?.toString() == f)
                          .length,
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
                      'No plans match these filters. Try All or another search.',
                )
              else
                ...filtered.map((p) => _PlanCard(
                      plan: p,
                      exercises: _exercises,
                      expanded: _expanded.contains((p['id'] as num?)?.toInt()),
                      onToggleExpand: () {
                        final id = (p['id'] as num?)?.toInt();
                        if (id == null) return;
                        setState(() {
                          if (_expanded.contains(id)) {
                            _expanded.remove(id);
                          } else {
                            _expanded.add(id);
                          }
                        });
                      },
                      onDelete: () async {
                        final id = (p['id'] as num).toInt();
                        try {
                          await ref.read(vivrantApiProvider).deleteGymPlan(id);
                          if (!mounted) return;
                          setState(() {
                            _plans = _plans
                                .where((item) => (item['id'] as num).toInt() != id)
                                .toList();
                            _expanded.remove(id);
                          });
                          ref
                              .read(moduleCacheProvider)
                              .write(ModuleCacheKeys.gymPlans, _plans);
                          context.showSuccess('Plan removed');
                        } catch (e) {
                          if (!mounted) return;
                          context.showError(apiErrorMessage(e));
                        }
                      },
                    )),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExerciseChecklist extends StatelessWidget {
  const _ExerciseChecklist({
    required this.title,
    required this.exercises,
    required this.selected,
    required this.onToggle,
    required this.onDemo,
  });

  final String title;
  final List<GymExercise> exercises;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final ValueChanged<GymExercise> onDemo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final ex = exercises[index];
              final checked = selected.contains(ex.slug);
              return CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: checked,
                onChanged: (_) => onToggle(ex.slug),
                title: Text(ex.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${humanizeLabel(ex.muscleGroup)} · ${humanizeLabel(ex.equipment)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                secondary: ex.hasDemo
                    ? IconButton(
                        tooltip: 'Demo',
                        onPressed: () => onDemo(ex),
                        icon: const Icon(Icons.play_circle_outline),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.exercises,
    required this.expanded,
    required this.onToggleExpand,
    required this.onDelete,
  });

  final Map<String, dynamic> plan;
  final List<GymExercise> exercises;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final daysPerWeek = plan['days_per_week'] ?? (plan['days'] is List ? (plan['days'] as List).length : null);
    final summary = plan['summary']?.toString();
    final days = (plan['days'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: VivrantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title']?.toString() ?? 'Plan',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${humanizeLabel(plan['focus']?.toString() ?? 'plan')} · ${plan['level'] ?? '—'} · ${daysPerWeek ?? '—'} days/wk',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: expanded ? 'Hide days' : 'Show days',
                  onPressed: onToggleExpand,
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (summary != null && summary.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(summary, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (expanded && days.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final day in days) ...[
                Text(
                  '${day['day'] ?? 'Day'} · ${humanizeLabel(day['focus']?.toString() ?? '')}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                for (final raw in (day['exercises'] as List? ?? const []))
                  Builder(
                    builder: (context) {
                      final ex = Map<String, dynamic>.from(raw as Map);
                      final name = ex['name']?.toString() ?? 'Movement';
                      final linked = findExerciseMatch(name, exercises);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$name · ${ex['sets'] ?? ''} · rest ${ex['rest'] ?? ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            if (linked != null && linked.hasDemo)
                              TextButton(
                                onPressed: () => showExerciseDemoSheet(context, linked),
                                child: const Text('Demo'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
