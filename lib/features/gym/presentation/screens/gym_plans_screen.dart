import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/utils/share_export.dart';
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
  final _knownQuery = TextEditingController();
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
  bool _showCustomize = false;
  String? _error;
  String _filter = 'all';
  String _knownMuscle = 'all';

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
    _knownQuery.dispose();
    _customCtrl.dispose();
    _daysCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  Future<void> _restorePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final days = int.tryParse(prefs.getString(_prefsDaysKey) ?? '') ?? 3;
    final session = int.tryParse(prefs.getString(_prefsSessionKey) ?? '') ?? 45;
    setState(() {
      _daysCtrl.text = days.clamp(2, 6).toString();
      _sessionCtrl.text = session.clamp(15, 120).toString();
      _knownSlugs
        ..clear()
        ..addAll(sanitizeKnownMachineSlugs(prefs.getStringList(_prefsKnownKey) ?? const []));
      _customExercises
        ..clear()
        ..addAll(sanitizeCustomExercises(prefs.getStringList(_prefsCustomKey) ?? const []));
      _avoidTargets
        ..clear()
        ..addAll(sanitizeAvoidTargets(prefs.getStringList(_prefsAvoidKey) ?? const []));
    });
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final known = sanitizeKnownMachineSlugs(_knownSlugs);
    final customs = sanitizeCustomExercises(_customExercises);
    final avoids = sanitizeAvoidTargets(_avoidTargets);
    if (!mounted) return;
    if (known.length != _knownSlugs.length ||
        customs.length != _customExercises.length ||
        avoids.length != _avoidTargets.length) {
      setState(() {
        _knownSlugs
          ..clear()
          ..addAll(known);
        _customExercises
          ..clear()
          ..addAll(customs);
        _avoidTargets
          ..clear()
          ..addAll(avoids);
      });
    }
    await prefs.setString(_prefsDaysKey, _daysPerWeek.toString());
    await prefs.setString(_prefsSessionKey, _sessionMinutes.toString());
    await prefs.setStringList(_prefsKnownKey, known);
    await prefs.setStringList(_prefsCustomKey, customs);
    await prefs.setStringList(_prefsAvoidKey, avoids);
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
      context.showSuccess('Your program is ready');
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _addCustom() {
    final cleaned = sanitizeCustomExercises([_customCtrl.text]);
    if (cleaned.isEmpty) return;
    final name = cleaned.first;
    final exists = _customExercises.any((e) => e.toLowerCase() == name.toLowerCase());
    if (exists || _customExercises.length >= 20) {
      _customCtrl.clear();
      return;
    }
    setState(() {
      _customExercises.add(name);
      _customCtrl.clear();
    });
    _persistPrefs();
  }

  void _toggleKnown(String slug) {
    final cleaned = sanitizeKnownMachineSlugs([slug]);
    if (cleaned.isEmpty) return;
    final key = cleaned.first;
    setState(() {
      if (_knownSlugs.contains(key)) {
        _knownSlugs.remove(key);
      } else if (_knownSlugs.length < 60) {
        _knownSlugs.add(key);
      }
    });
    _persistPrefs();
  }

  void _clearKnown() {
    setState(() {
      _knownSlugs.clear();
      _customExercises.clear();
    });
    _persistPrefs();
  }

  void _toggleSelectAllKnownInView() {
    final visible = _visibleKnownExercises.map((e) => e.slug).toList(growable: false);
    if (visible.isEmpty) return;
    final allSelected = visible.every(_knownSlugs.contains);
    setState(() {
      if (allSelected) {
        _knownSlugs.removeAll(visible);
      } else {
        for (final slug in visible) {
          if (_knownSlugs.length >= 60) break;
          _knownSlugs.add(slug);
        }
      }
    });
    _persistPrefs();
  }

  bool _matchesKnownSearch(GymExercise exercise, String q) {
    if (q.isEmpty) return true;
    return exercise.name.toLowerCase().contains(q) ||
        exercise.muscleGroup.toLowerCase().contains(q) ||
        exercise.equipment.toLowerCase().contains(q);
  }

  List<GymExercise> _filterKnownList(List<GymExercise> source) {
    final q = _knownQuery.text.trim().toLowerCase();
    return source
        .where(
          (exercise) =>
              matchesMuscleFilter(exercise.muscleGroup, _knownMuscle) &&
              _matchesKnownSearch(exercise, q),
        )
        .toList(growable: false);
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

  List<GymExercise> get _filteredMachines => _filterKnownList(_machines);

  List<GymExercise> get _filteredFreeWeights => _filterKnownList(_freeWeights);

  List<GymExercise> get _visibleKnownExercises =>
      [..._filteredMachines, ..._filteredFreeWeights];

  bool get _allVisibleKnownSelected {
    final visible = _visibleKnownExercises;
    return visible.isNotEmpty && visible.every((e) => _knownSlugs.contains(e.slug));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Training program'),
        actions: [
          if (_plans.isNotEmpty)
            ShareExportButton(doc: gymPlansDoc(_plans)),
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
              highlight: 'program',
            ),
            Text(
              'Create a simple weekly program that fits your schedule.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            VivrantPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How often do you train?',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose days and minutes, then create a program. Extra options are optional.',
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
                            labelText: 'Days per week',
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
                            labelText: 'Minutes per workout',
                            helperText: '15–120',
                          ),
                          onChanged: (_) => _persistPrefs(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _generating ? null : _createAi,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        _generating ? 'Creating your program…' : 'Create my program',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _showCustomize = !_showCustomize),
                    icon: Icon(
                      _showCustomize
                          ? Icons.expand_less
                          : Icons.tune_rounded,
                    ),
                    label: Text(
                      _showCustomize
                          ? 'Hide optional settings'
                          : 'Customize (optional)',
                    ),
                  ),
                  if (_showCustomize) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Skip these areas',
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
                      'Moves you already know',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optional: mark exercises you know so your program can prefer them.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(
                          label: Text(
                            '${_knownSlugs.length + _customExercises.length} selected',
                          ),
                        ),
                        if (_visibleKnownExercises.isNotEmpty)
                          TextButton(
                            onPressed: _toggleSelectAllKnownInView,
                            child: Text(
                              _allVisibleKnownSelected
                                  ? 'Clear these'
                                  : 'Select these (${_visibleKnownExercises.length})',
                            ),
                          ),
                        if (_knownSlugs.isNotEmpty ||
                            _customExercises.isNotEmpty)
                          TextButton(
                            onPressed: _clearKnown,
                            child: const Text('Clear all'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    VivrantSearchField(
                      controller: _knownQuery,
                      hintText: 'Search exercises…',
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    VivrantFilterChips<String>(
                      options: [
                        for (final muscle in gymMuscleFilters)
                          VivrantFilterOption(
                            value: muscle,
                            label: muscleFilterLabel(muscle),
                          ),
                      ],
                      selected: _knownMuscle,
                      onSelected: (v) => setState(() => _knownMuscle = v),
                    ),
                    const SizedBox(height: 10),
                    _ExerciseChecklist(
                      title: 'Machines (${_filteredMachines.length})',
                      exercises: _filteredMachines,
                      emptyMessage: _machines.isEmpty
                          ? 'No machines listed yet.'
                          : 'No machines match this search.',
                      selected: _knownSlugs,
                      onToggle: _toggleKnown,
                      onDemo: (ex) => showExerciseDemoSheet(context, ex),
                    ),
                    const SizedBox(height: 10),
                    _ExerciseChecklist(
                      title:
                          'Free weights & bodyweight (${_filteredFreeWeights.length})',
                      exercises: _filteredFreeWeights,
                      emptyMessage: _freeWeights.isEmpty
                          ? 'No free-weight moves listed yet.'
                          : 'No free-weight moves match this search.',
                      selected: _knownSlugs,
                      onToggle: _toggleKnown,
                      onDemo: (ex) => showExerciseDemoSheet(context, ex),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Other moves',
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
                              hintText: 'e.g. Hip thrust…',
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
                  ],
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
                  child: const Text('Try again'),
                ),
              )
            else if (_plans.isEmpty)
              EmptyState(
                title: 'No program yet',
                message: 'Choose how often you train above, then create a program.',
                action: ElevatedButton(
                  onPressed: _generating ? null : _createAi,
                  child: const Text('Create my program'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search programs…',
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
                      'No programs match these filters. Try All or another search.',
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
                      onShare: () => showShareExportSheet(context, gymPlanDoc(p)),
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
                          context.showSuccess('Program removed');
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
    required this.emptyMessage,
    required this.selected,
    required this.onToggle,
    required this.onDemo,
  });

  final String title;
  final List<GymExercise> exercises;
  final String emptyMessage;
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
        if (exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
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
                  title: Row(
                    children: [
                      _KnownExerciseThumb(exercise: ex),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ex.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${humanizeLabel(ex.muscleGroup)} · ${humanizeLabel(ex.equipment)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _KnownExerciseThumb extends StatelessWidget {
  const _KnownExerciseThumb({
    required this.exercise,
    this.size = 40,
  });

  final GymExercise exercise;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final thumb = exercise.demoThumbnailUrl?.trim();
    final hasThumb = thumb != null && thumb.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: hasThumb
            ? CachedNetworkImage(
                imageUrl: thumb,
                fit: BoxFit.cover,
                placeholder: (_, __) => ColoredBox(
                  color: c.accentSoft,
                  child: Icon(muscleIcon(exercise.muscleGroup), color: c.accent, size: 18),
                ),
                errorWidget: (_, __, ___) => ColoredBox(
                  color: c.accentSoft,
                  child: Icon(muscleIcon(exercise.muscleGroup), color: c.accent, size: 18),
                ),
              )
            : ColoredBox(
                color: c.accentSoft,
                child: Icon(muscleIcon(exercise.muscleGroup), color: c.accent, size: 18),
              ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.exercises,
    required this.expanded,
    required this.onToggleExpand,
    required this.onShare,
    required this.onDelete,
  });

  final Map<String, dynamic> plan;
  final List<GymExercise> exercises;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final daysPerWeek = plan['days_per_week'] ?? (plan['days'] is List ? (plan['days'] as List).length : null);
    final summary = plan['summary']?.toString();
    final recs = programRecommendations(plan);
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
                        plan['title']?.toString() ?? 'Program',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${humanizeLabel(plan['focus']?.toString() ?? 'program')} · ${plan['level'] ?? '—'} · ${daysPerWeek ?? '—'} days/wk',
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
                  tooltip: 'Share or export',
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: onShare,
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
            if (recs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Coach notes',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              for (final rec in recs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
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
                      final notes = ex['notes']?.toString() ?? '';
                      final linked = findExerciseMatch(name, exercises);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (linked != null) ...[
                              _KnownExerciseThumb(exercise: linked, size: 32),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatGymExerciseLine(ex),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (notes.isNotEmpty)
                                    Text(
                                      notes,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                          ),
                                    ),
                                ],
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
                if (dayAlternatives(day).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Alternatives',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  for (final swap in dayAlternatives(day))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${swap['use']} instead of ${swap['instead_of']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (dayAdditionals(day).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Add-ons',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  for (final addon in dayAdditionals(day))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addon['sets'] != null && addon['sets']!.isNotEmpty
                                  ? '${addon['name']} · ${addon['sets']}'
                                  : addon['name'] ?? '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
