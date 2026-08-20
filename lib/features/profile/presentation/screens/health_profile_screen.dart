import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/auth_provider.dart';

class HealthProfileScreen extends ConsumerStatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  ConsumerState<HealthProfileScreen> createState() =>
      _HealthProfileScreenState();
}

class _HealthProfileScreenState extends ConsumerState<HealthProfileScreen> {
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  final _steps = TextEditingController();
  final _water = TextEditingController();
  final _budget = TextEditingController();

  DateTime? _birthDate;
  String? _sex;
  String? _activityLevel;
  String? _healthFocus;
  bool _loading = false;
  bool _initialized = false;

  static const _sexOptions = <(String, String)>[
    ('female', 'Female'),
    ('male', 'Male'),
    ('non_binary', 'Non-binary'),
    ('prefer_not_to_say', 'Prefer not to say'),
  ];

  static const _activityOptions = <(String, String)>[
    ('sedentary', 'Sedentary'),
    ('light', 'Lightly active'),
    ('moderate', 'Moderately active'),
    ('active', 'Active'),
    ('very_active', 'Very active'),
  ];

  static const _focusOptions = <(String, String)>[
    ('general', 'General vitality'),
    ('weight', 'Weight management'),
    ('strength', 'Strength'),
    ('endurance', 'Endurance'),
    ('nutrition', 'Nutrition'),
    ('sleep', 'Sleep'),
    ('stress', 'Stress management'),
  ];

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _steps.dispose();
    _water.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _sync(Profile? profile) {
    if (_initialized || profile == null) return;
    _height.text = profile.heightCm?.toString() ?? '';
    _weight.text = profile.weightKg?.toString() ?? '';
    _goalWeight.text = profile.goalWeightKg?.toString() ?? '';
    _steps.text = '${profile.dailyStepGoal}';
    _water.text = '${profile.dailyWaterGoalMl}';
    _budget.text = profile.monthlyHealthBudget?.toString() ?? '';
    if (profile.birthDate != null && profile.birthDate!.isNotEmpty) {
      _birthDate = DateTime.tryParse(profile.birthDate!);
    }
    _sex = profile.sex;
    _activityLevel = profile.activityLevel;
    _healthFocus = profile.healthFocus ?? 'general';
    _initialized = true;
  }

  String _birthLabel() {
    if (_birthDate == null) return 'Add birth date';
    final d = _birthDate!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  double? get _bmi {
    final h = double.tryParse(_height.text.trim());
    final w = double.tryParse(_weight.text.trim());
    if (h == null || w == null || h <= 0) return null;
    return w / ((h / 100) * (h / 100));
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'birth_date': _birthDate == null
            ? null
            : '${_birthDate!.year.toString().padLeft(4, '0')}-'
                '${_birthDate!.month.toString().padLeft(2, '0')}-'
                '${_birthDate!.day.toString().padLeft(2, '0')}',
        'sex': _sex,
        'height_cm': double.tryParse(_height.text.trim()),
        'weight_kg': double.tryParse(_weight.text.trim()),
        'goal_weight_kg': double.tryParse(_goalWeight.text.trim()),
        'activity_level': _activityLevel,
        'health_focus': _healthFocus,
        'daily_step_goal': int.tryParse(_steps.text.trim()) ?? 8000,
        'daily_water_goal_ml': int.tryParse(_water.text.trim()) ?? 2500,
        'monthly_health_budget': double.tryParse(_budget.text.trim()) ?? 0,
      };
      final updated = await ref.read(vivrantApiProvider).updateProfile(body);
      await ref.read(authProvider.notifier).refreshProfile(updated);
      if (!mounted) return;
      context.showSuccess('Health profile saved');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    _sync(profile);
    final theme = Theme.of(context);
    final c = VivrantColors.of(context);
    final bmi = _bmi;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Health profile')),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'You',
            title: 'Health',
            highlight: 'profile',
          ),
          Text(
            'Body stats used for BMI, coaching, and goals.',
            style: theme.textTheme.bodyMedium,
          ),
          const SectionGap(),
          VivrantPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Birth date',
                      prefixIcon: Icon(
                        Icons.cake_outlined,
                        size: 20,
                        color: c.muted,
                      ),
                    ),
                    child: Text(
                      _birthLabel(),
                      style: TextStyle(
                        color: _birthDate == null ? c.muted : c.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String?>(
                  key: ValueKey('sex-$_sex'),
                  initialValue: _sex,
                  decoration: InputDecoration(
                    labelText: 'Sex',
                    prefixIcon: Icon(Icons.wc_outlined, size: 20, color: c.muted),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Prefer not to set'),
                    ),
                    ..._sexOptions.map(
                      (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sex = v),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _height,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Height',
                    suffixText: 'cm',
                    prefixIcon: Icon(
                      Icons.height_rounded,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _weight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    suffixText: 'kg',
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _goalWeight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Goal weight',
                    suffixText: 'kg',
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                if (bmi != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    'BMI ${bmi.toStringAsFixed(1)} · screening measure only',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                DropdownButtonFormField<String?>(
                  key: ValueKey('activity-$_activityLevel'),
                  initialValue: _activityLevel,
                  decoration: InputDecoration(
                    labelText: 'Activity level',
                    prefixIcon: Icon(
                      Icons.directions_run_rounded,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Select activity level'),
                    ),
                    ..._activityOptions.map(
                      (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _activityLevel = v),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String?>(
                  key: ValueKey('focus-$_healthFocus'),
                  initialValue: _healthFocus,
                  decoration: InputDecoration(
                    labelText: 'Primary health focus',
                    prefixIcon: Icon(
                      Icons.spa_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                  items: _focusOptions
                      .map(
                        (o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _healthFocus = v),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _steps,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Daily step goal',
                    suffixText: 'steps',
                    prefixIcon: Icon(
                      Icons.directions_walk_rounded,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _water,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Daily water goal',
                    suffixText: 'ml',
                    prefixIcon: Icon(
                      Icons.water_drop_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _budget,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monthly health budget',
                    suffixText: 'PHP',
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      size: 20,
                      color: c.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: _loading ? 'Saving…' : 'Save health profile',
                  loading: _loading,
                  onPressed: _save,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
