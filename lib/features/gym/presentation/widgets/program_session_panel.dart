import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../gym_labels.dart';

class ProgramSessionPanel extends ConsumerStatefulWidget {
  const ProgramSessionPanel({
    super.key,
    required this.plans,
    this.onLogged,
  });

  final List<Map<String, dynamic>> plans;
  final VoidCallback? onLogged;

  @override
  ConsumerState<ProgramSessionPanel> createState() => _ProgramSessionPanelState();
}

class _RunnerItem {
  _RunnerItem({
    required this.key,
    required this.name,
    required this.originalName,
    required this.setsLabel,
    required this.rest,
    required this.restSeconds,
    required this.setCount,
    required this.kind,
    this.weight,
    this.notes,
    this.swap,
  });

  final String key;
  final String name;
  final String originalName;
  final String setsLabel;
  final String rest;
  final int restSeconds;
  final int setCount;
  final String kind;
  final String? weight;
  final String? notes;
  final String? swap;
}

class _ProgramSessionPanelState extends ConsumerState<ProgramSessionPanel> {
  int? _planId;
  Map<String, List<bool>> _checks = {};
  Map<String, String> _names = {};
  DateTime? _startedAt;
  bool _saving = false;

  Timer? _ticker;
  int _restLeft = 0;
  int _restTotal = 0;
  String? _restLabel;

  @override
  void initState() {
    super.initState();
    _planId = widget.plans.isEmpty ? null : (widget.plans.first['id'] as num?)?.toInt();
    _resetFromPlan();
  }

  @override
  void didUpdateWidget(covariant ProgramSessionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_planId == null && widget.plans.isNotEmpty) {
      _planId = (widget.plans.first['id'] as num?)?.toInt();
      _resetFromPlan();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Map<String, dynamic>? get _plan {
    if (widget.plans.isEmpty) return null;
    for (final plan in widget.plans) {
      if ((plan['id'] as num?)?.toInt() == _planId) return plan;
    }
    return widget.plans.first;
  }

  Map<String, dynamic>? get _today {
    final plan = _plan;
    if (plan == null) return null;
    final days = (plan['days'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return pickTodaysPlanDay(days, null, planTrainingDaysList(plan));
  }

  List<_RunnerItem> get _items {
    final today = _today;
    if (today == null) return const [];
    return _buildItems(today);
  }

  List<_RunnerItem> _buildItems(Map<String, dynamic> day) {
    final alternatives = dayAlternatives(day);
    final exercises = (day['exercises'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final mains = <_RunnerItem>[
      for (var i = 0; i < exercises.length; i++)
        _RunnerItem(
          key: 'main-$i',
          name: exercises[i]['name']?.toString() ?? 'Movement',
          originalName: exercises[i]['name']?.toString() ?? 'Movement',
          setsLabel: exercises[i]['sets']?.toString() ?? '3 x 10',
          rest: exercises[i]['rest']?.toString() ?? '60s',
          restSeconds: parseRestSeconds(exercises[i]['rest']?.toString() ?? '60s'),
          setCount: parseSetCount(exercises[i]['sets']?.toString() ?? '3 x 10'),
          kind: 'main',
          weight: (exercises[i]['weight']?.toString() ?? '').trim().isEmpty
              ? null
              : exercises[i]['weight'].toString(),
          notes: (exercises[i]['notes']?.toString() ?? '').trim().isEmpty
              ? null
              : exercises[i]['notes'].toString(),
          swap: alternatives
              .where(
                (alt) =>
                    (alt['instead_of'] ?? '').toLowerCase() ==
                    (exercises[i]['name']?.toString() ?? '').toLowerCase(),
              )
              .map((alt) => alt['use'])
              .firstOrNull,
        ),
    ];
    final addons = dayAdditionals(day);
    return [
      ...mains,
      for (var i = 0; i < addons.length; i++)
        _RunnerItem(
          key: 'addon-$i',
          name: addons[i]['name'] ?? 'Extra',
          originalName: addons[i]['name'] ?? 'Extra',
          setsLabel: addons[i]['sets'] ?? '2 x 12',
          rest: '45s',
          restSeconds: 45,
          setCount: parseSetCount(addons[i]['sets'] ?? '2 x 12'),
          kind: 'addon',
        ),
    ];
  }

  void _resetFromPlan() {
    final items = _items;
    _checks = {
      for (final item in items) item.key: List<bool>.filled(item.setCount, false),
    };
    _names = {for (final item in items) item.key: item.name};
  }

  int get _doneCount =>
      _checks.values.fold<int>(0, (sum, row) => sum + row.where((on) => on).length);

  int get _totalCount =>
      _items.fold<int>(0, (sum, item) => sum + item.setCount);

  int get _elapsedMinutes {
    final start = _startedAt;
    if (start == null) return 45;
    final mins = DateTime.now().difference(start).inMinutes;
    return mins.clamp(5, 180);
  }

  void _startRest(int seconds, String label) {
    if (seconds <= 0) return;
    _ticker?.cancel();
    setState(() {
      _restLeft = seconds;
      _restTotal = seconds;
      _restLabel = label;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restLeft <= 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        setState(() {
          _restLeft = 0;
          _restLabel = null;
        });
        context.showSuccess('Rest done — next set');
        return;
      }
      setState(() => _restLeft--);
    });
  }

  void _skipRest() {
    _ticker?.cancel();
    setState(() {
      _restLeft = 0;
      _restLabel = null;
    });
  }

  void _toggleSet(_RunnerItem item, int index) {
    final current = List<bool>.from(_checks[item.key] ?? List<bool>.filled(item.setCount, false));
    current[index] = !current[index];
    setState(() {
      _checks[item.key] = current;
      _startedAt ??= DateTime.now();
    });
    if (!current[index]) return;
    HapticFeedback.selectionClick();
    final stillOpen = _items.any((row) {
      final rowChecks = row.key == item.key ? current : (_checks[row.key] ?? const <bool>[]);
      return rowChecks.any((on) => !on);
    });
    if (stillOpen) _startRest(item.restSeconds, _names[item.key] ?? item.name);
  }

  void _toggleExercise(_RunnerItem item) {
    final current = _checks[item.key] ?? List<bool>.filled(item.setCount, false);
    final allOn = current.isNotEmpty && current.every((on) => on);
    setState(() {
      _checks[item.key] = List<bool>.filled(item.setCount, !allOn);
      if (!allOn) _startedAt ??= DateTime.now();
    });
    if (allOn) return;
    HapticFeedback.selectionClick();
    _startRest(item.restSeconds, _names[item.key] ?? item.name);
  }

  void _swap(_RunnerItem item) {
    final swap = item.swap;
    if (swap == null) return;
    setState(() {
      final current = _names[item.key] ?? item.name;
      _names[item.key] = current == item.originalName ? swap : item.originalName;
    });
  }

  Future<void> _save() async {
    final plan = _plan;
    final today = _today;
    if (plan == null || today == null) return;
    final logged = <Map<String, dynamic>>[];
    for (final item in _items) {
      final row = _checks[item.key] ?? const <bool>[];
      final completed = row.where((on) => on).length;
      if (completed == 0) continue;
      logged.add({
        'name': _names[item.key] ?? item.name,
        'sets': item.setsLabel,
        'rest': item.rest,
        if (item.weight != null) 'weight': item.weight,
        'done': completed >= item.setCount,
        'completed_sets': completed,
      });
    }
    if (logged.isEmpty) {
      context.showError('Check off at least one set, then save.');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(vivrantApiProvider).logGymSession({
        'title': '${today['day'] ?? 'Today'}: ${humanizeLabel(today['focus']?.toString() ?? 'workout')}',
        'focus': gymSessionFocusFromPlan(today['focus']?.toString() ?? 'full_body'),
        'duration_minutes': _elapsedMinutes,
        'notes': 'From program: ${plan['title'] ?? 'gym'}',
        'exercises': logged,
      });
      if (!mounted) return;
      _ticker?.cancel();
      setState(() {
        _saving = false;
        _startedAt = null;
        _restLabel = null;
        _restLeft = 0;
        _resetFromPlan();
      });
      context.showSuccess('Workout saved from your program');
      widget.onLogged?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    if (widget.plans.isEmpty) {
      return VivrantPanel(
        title: "Today's program",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a weekly program first — then today’s exercises show up here with checkboxes and a rest timer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/gym/plans'),
              child: const Text('Create a program'),
            ),
          ],
        ),
      );
    }

    final plan = _plan;
    final today = _today;
    if (plan == null || today == null) {
      return const VivrantPanel(
        title: "Today's program",
        child: Text('Rest day — no session on your schedule today.'),
      );
    }

    final items = _items;
    return VivrantPanel(
      title: "Today's program",
      trailing: Text(
        '$_doneCount/$_totalCount sets',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: c.accent,
          fontSize: 12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check off each set. Rest starts from the program — skip anytime.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.plans.length > 1) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              key: ValueKey(_planId),
              initialValue: (plan['id'] as num?)?.toInt(),
              decoration: const InputDecoration(labelText: 'Program'),
              items: [
                for (final item in widget.plans)
                  DropdownMenuItem(
                    value: (item['id'] as num?)?.toInt(),
                    child: Text(item['title']?.toString() ?? 'Program'),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _planId = value;
                  _resetFromPlan();
                });
              },
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.accentSoft.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${today['day'] ?? 'Today'} · ${humanizeLabel(today['focus']?.toString() ?? '')}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plan['title']?.toString() ?? 'Program',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (_restLabel != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? VivrantColors.darkInk
                    : VivrantColors.ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REST · $_restLabel',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          formatRestClock(_restLeft),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_restTotal > 0)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        value: _restLeft / _restTotal,
                        color: c.accent,
                        backgroundColor: Colors.white24,
                        strokeWidth: 3,
                      ),
                    ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _skipRest,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final item in items) ...[
            _ExerciseCard(
              item: item,
              name: _names[item.key] ?? item.name,
              checks: _checks[item.key] ?? const [],
              onToggleExercise: () => _toggleExercise(item),
              onToggleSet: (index) => _toggleSet(item, index),
              onSwap: item.swap == null ? null : () => _swap(item),
            ),
            const SizedBox(height: 10),
          ],
          ElevatedButton(
            onPressed: _saving || _doneCount == 0 ? null : _save,
            child: Text(
              _saving ? 'Saving…' : 'Save workout · $_elapsedMinutes min',
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.item,
    required this.name,
    required this.checks,
    required this.onToggleExercise,
    required this.onToggleSet,
    this.onSwap,
  });

  final _RunnerItem item;
  final String name;
  final List<bool> checks;
  final VoidCallback onToggleExercise;
  final ValueChanged<int> onToggleSet;
  final VoidCallback? onSwap;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    final complete = checks.isNotEmpty && checks.every((on) => on);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complete ? c.accentSoft.withValues(alpha: 0.55) : c.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete ? c.accent.withValues(alpha: 0.35) : c.ink.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: complete,
                onChanged: (_) => onToggleExercise(),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                        [
                          item.setsLabel,
                          if (item.weight != null) item.weight,
                          if (item.restSeconds > 0) 'rest ${item.rest}',
                          if (item.kind == 'addon') 'extra',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (item.notes != null)
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 6),
              child: Text(item.notes!, style: Theme.of(context).textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < checks.length; i++)
                  FilterChip(
                    label: Text('Set ${i + 1}'),
                    selected: checks[i],
                    onSelected: (_) => onToggleSet(i),
                  ),
              ],
            ),
          ),
          if (onSwap != null)
            TextButton.icon(
              onPressed: onSwap,
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(
                name == item.originalName
                    ? 'Swap for ${item.swap}'
                    : 'Back to ${item.originalName}',
              ),
            ),
        ],
      ),
    );
  }
}
