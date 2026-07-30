import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  final _goalWeight = TextEditingController();
  final _steps = TextEditingController();
  final _water = TextEditingController();
  final _budget = TextEditingController();
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();

  DateTime? _birthDate;
  String? _sex;
  String? _activityLevel;
  String? _healthFocus;

  bool _loading = false;
  bool _avatarBusy = false;
  bool _initialized = false;
  late final AnimationController _enter;

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
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    _name.dispose();
    _bio.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _steps.dispose();
    _water.dispose();
    _budget.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  void _syncControllers(Profile? profile) {
    if (_initialized || profile == null) return;
    _name.text = profile.displayName;
    _bio.text = profile.bio ?? '';
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
        'display_name': _name.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
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
        'monthly_health_budget':
            double.tryParse(_budget.text.trim()) ?? 0,
      };
      final updated = await ref.read(vivrantApiProvider).updateProfile(body);
      await ref.read(authProvider.notifier).refreshProfile(updated);
      if (!mounted) return;
      context.showSuccess('Profile updated');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove avatar?'),
        content: const Text('Your profile photo will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _avatarBusy = true);
    try {
      await ref.read(vivrantApiProvider).deleteAvatar();
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.showSuccess('Avatar removed');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _showAvatarActions() async {
    HapticFeedback.selectionClick();
    final hasAvatar =
        (ref.read(authProvider).profile?.avatarUrl ?? '').isNotEmpty;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera'),
              ),
              if (hasAvatar)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(ctx).colorScheme.error,
                  ),
                  title: Text(
                    'Remove avatar',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
                  onTap: () => Navigator.pop(ctx, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) return;
    if (action == 'remove') {
      await _removeAvatar();
      return;
    }

    final source =
        action == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 88,
    );
    if (file == null || !mounted) return;

    setState(() => _avatarBusy = true);
    try {
      await ref.read(vivrantApiProvider).uploadAvatar(file.path);
      await ref.read(authProvider.notifier).refreshProfile();
      if (!mounted) return;
      context.showSuccess('Avatar updated');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Animation<double> _fade(double begin, double end) {
    return CurvedAnimation(
      parent: _enter,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  Animation<Offset> _slide(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _reveal({
    required double start,
    required double finish,
    required Widget child,
  }) {
    return FadeTransition(
      opacity: _fade(start, finish),
      child: SlideTransition(
        position: _slide(start, finish),
        child: child,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider).profile;
    _syncControllers(profile);

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;
    final displayName = profile?.displayName ?? _name.text;
    final email = profile?.email ?? '';
    final bmi = _bmi;

    return GradientScaffold(
      appBar: AppBar(title: const Text('Profile')),
      child: Stack(
        children: [
          const _ProfileAtmosphere(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _reveal(
                start: 0.0,
                finish: 0.45,
                child: PageHeader(
                  eyebrow: 'You',
                  title: 'Your',
                  highlight: 'profile',
                  trailing: _AvatarBadge(
                    initials: _initials(displayName),
                    avatarUrl: profile?.avatarUrl,
                    busy: _avatarBusy,
                    onTap: _showAvatarActions,
                  ),
                ),
              ),
              _reveal(
                start: 0.05,
                finish: 0.48,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _avatarBusy ? null : _showAvatarActions,
                        icon: const Icon(Icons.camera_alt_outlined, size: 16),
                        label: Text(
                          (profile?.avatarUrl ?? '').isEmpty
                              ? 'Add photo'
                              : 'Change photo',
                        ),
                      ),
                      if ((profile?.avatarUrl ?? '').isNotEmpty)
                        TextButton.icon(
                          onPressed: _avatarBusy ? null : _removeAvatar,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove'),
                        ),
                    ],
                  ),
                ),
              ),
              if (email.isNotEmpty)
                _reveal(
                  start: 0.08,
                  finish: 0.5,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 14, color: muted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              _reveal(
                start: 0.12,
                finish: 0.58,
                child: _SoftCard(
                  color: panel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'About you',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How you show up across Vivrant.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _name,
                        focusNode: _nameFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _bioFocus.requestFocus(),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Display name',
                          hintText: 'Your name',
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bio,
                        focusNode: _bioFocus,
                        maxLines: 3,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          hintText: 'A short note about you',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(bottom: 42),
                            child: Icon(
                              Icons.edit_note_rounded,
                              size: 20,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _reveal(
                start: 0.18,
                finish: 0.64,
                child: _SoftCard(
                  color: panel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Health profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Body stats used for BMI, coaching, and goals.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(14),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Birth date',
                            prefixIcon: Icon(
                              Icons.cake_outlined,
                              size: 20,
                              color: muted,
                            ),
                          ),
                          child: Text(
                            _birthLabel(),
                            style: TextStyle(
                              color: _birthDate == null ? muted : ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        key: ValueKey('sex-$_sex'),
                        initialValue: _sex,
                        decoration: InputDecoration(
                          labelText: 'Sex',
                          prefixIcon: Icon(
                            Icons.wc_outlined,
                            size: 20,
                            color: muted,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Prefer not to set'),
                          ),
                          ..._sexOptions.map(
                            (o) => DropdownMenuItem(
                              value: o.$1,
                              child: Text(o.$2),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _sex = v),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _height,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Height',
                                suffixText: 'cm',
                                prefixIcon: Icon(
                                  Icons.height_rounded,
                                  size: 20,
                                  color: muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _weight,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Weight',
                                suffixText: 'kg',
                                prefixIcon: Icon(
                                  Icons.monitor_weight_outlined,
                                  size: 20,
                                  color: muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _goalWeight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Goal weight',
                          suffixText: 'kg',
                          prefixIcon: Icon(
                            Icons.flag_outlined,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      if (bmi != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: soft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.favorite_outline, color: accent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'BMI ${bmi.toStringAsFixed(1)} · screening measure only',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        key: ValueKey('activity-$_activityLevel'),
                        initialValue: _activityLevel,
                        decoration: InputDecoration(
                          labelText: 'Activity level',
                          prefixIcon: Icon(
                            Icons.directions_run_rounded,
                            size: 20,
                            color: muted,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Select activity level'),
                          ),
                          ..._activityOptions.map(
                            (o) => DropdownMenuItem(
                              value: o.$1,
                              child: Text(o.$2),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _activityLevel = v),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String?>(
                        key: ValueKey('focus-$_healthFocus'),
                        initialValue: _healthFocus,
                        decoration: InputDecoration(
                          labelText: 'Primary health focus',
                          prefixIcon: Icon(
                            Icons.spa_outlined,
                            size: 20,
                            color: muted,
                          ),
                        ),
                        items: _focusOptions
                            .map(
                              (o) => DropdownMenuItem(
                                value: o.$1,
                                child: Text(o.$2),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _healthFocus = v),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _steps,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Daily step goal',
                          suffixText: 'steps',
                          prefixIcon: Icon(
                            Icons.directions_walk_rounded,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _water,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Daily water goal',
                          suffixText: 'ml',
                          prefixIcon: Icon(
                            Icons.water_drop_outlined,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _budget,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Monthly health budget',
                          suffixText: 'PHP',
                          prefixIcon: Icon(
                            Icons.payments_outlined,
                            size: 20,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        label: _loading ? 'Saving…' : 'Save health profile',
                        loading: _loading,
                        onPressed: _save,
                        icon: Icons.check_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _reveal(
                start: 0.28,
                finish: 0.72,
                child: SectionLabel('More'),
              ),
              _reveal(
                start: 0.32,
                finish: 0.78,
                child: _SoftCard(
                  color: panel,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _NavRow(
                        icon: Icons.flag_outlined,
                        title: 'Goals',
                        subtitle: 'Targets you are working toward',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/goals'),
                      ),
                      _Divider(color: ink),
                      _NavRow(
                        icon: Icons.history_rounded,
                        title: 'Health history',
                        subtitle: 'Notes and past records',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/history'),
                      ),
                      _Divider(color: ink),
                      _NavRow(
                        icon: Icons.tune_rounded,
                        title: 'Preferences',
                        subtitle: 'Theme, alerts, and timezone',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/preferences'),
                      ),
                      _Divider(color: ink),
                      _NavRow(
                        icon: Icons.lock_outline_rounded,
                        title: 'Change password',
                        subtitle: 'Update web and mobile sign-in',
                        accent: accent,
                        soft: soft,
                        onTap: () => context.push('/profile/password'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _reveal(
                start: 0.48,
                finish: 0.92,
                child: _LogoutButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    await ref.read(authProvider.notifier).logout();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({
    required this.initials,
    this.avatarUrl,
    this.busy = false,
    this.onTap,
  });

  final String initials;
  final String? avatarUrl;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: dark
                  ? VivrantColors.darkBrandGradient
                  : VivrantColors.brandGradient,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: dark ? 0.28 : 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? VivrantColors.darkPanel : Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    )
                  : hasImage
                      ? CachedNetworkImage(
                          imageUrl: avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _Initials(initials: initials),
                        )
                      : _Initials(initials: initials),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dark ? VivrantColors.darkInk : VivrantColors.ink,
                border: Border.all(
                  color: dark ? VivrantColors.darkPanel : Colors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: 11,
                color: dark ? VivrantColors.darkPanel : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    final c = VivrantColors.of(context);
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.accentDeep,
        ),
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 18),
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.92 : 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: (dark ? VivrantColors.darkAccent : VivrantColors.accent)
                .withValues(alpha: dark ? 0.08 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NavRow extends StatefulWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.soft,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color soft;
  final VoidCallback onTap;

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? VivrantColors.darkMuted
        : VivrantColors.muted;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: widget.soft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.accent, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: muted,
                              fontSize: 12.5,
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedSlide(
                  offset: _pressed ? const Offset(0.12, 0) : Offset.zero,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Divider(height: 1, color: color.withValues(alpha: 0.06)),
    );
  }
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: panel.withValues(alpha: dark ? 0.7 : 0.85),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ink.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, size: 18, color: ink),
                const SizedBox(width: 8),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAtmosphere extends StatelessWidget {
  const _ProfileAtmosphere();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final c = dark ? VivrantColors.darkCyan : VivrantColors.cyan;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -70,
            child: _Blob(
              size: 200,
              color: a.withValues(alpha: dark ? 0.16 : 0.1),
            ),
          ),
          Positioned(
            top: 280,
            left: -90,
            child: _Blob(
              size: 180,
              color: c.withValues(alpha: dark ? 0.12 : 0.07),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
