import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class HealthHistoryScreen extends ConsumerStatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  ConsumerState<HealthHistoryScreen> createState() =>
      _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends ConsumerState<HealthHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..forward();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<Map<String, dynamic>>>(ModuleCacheKeys.healthHistory);
    if (cached != null) {
      _entries = List<Map<String, dynamic>>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.healthHistory);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final entries = await ref.read(vivrantApiProvider).healthHistory();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.healthHistory, entries);
      setState(() {
        _entries = entries;
        _loading = false;
      });
      _enter.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add history'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 2,
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty && mounted) {
      try {
        await ref.read(vivrantApiProvider).addHealthHistory({
          'title': title.text.trim(),
          if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
        });
        if (!mounted) return;
        HapticFeedback.lightImpact();
        context.showSuccess('Health history saved');
        await _load();
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Health history'),
        actions: [
          IconButton(
            onPressed: _add,
            tooltip: 'Add entry',
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _enter,
                curve: const Interval(0, 0.5, curve: Curves.easeOutCubic),
              ),
              child: const PageHeader(
                eyebrow: 'Records',
                title: 'Health',
                highlight: 'history',
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
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
            else if (_entries.isEmpty)
              EmptyState(
                message: 'No history entries yet. Add your first note.',
                action: PrimaryButton(
                  label: 'Add entry',
                  onPressed: _add,
                  icon: Icons.note_add_outlined,
                ),
              )
            else
              ...List.generate(_entries.length, (i) {
                final e = _entries[i];
                final start = (0.15 + i * 0.07).clamp(0.0, 0.7);
                final end = (start + 0.35).clamp(0.0, 1.0);
                final title = e['title']?.toString() ?? 'Entry';
                final note = e['note']?.toString();
                final date = e['created_at']?.toString() ??
                    e['date']?.toString() ??
                    e['recorded_at']?.toString();

                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _enter,
                    curve: Interval(start, end, curve: Curves.easeOutCubic),
                  ),
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: _enter,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: panel.withValues(alpha: dark ? 0.92 : 0.96),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ink.withValues(alpha: 0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: accent
                                  .withValues(alpha: dark ? 0.07 : 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: soft,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.history_edu_outlined,
                                color: accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      note,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (date != null && date.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      date.length > 16
                                          ? date.substring(0, 16)
                                          : date,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: muted.withValues(alpha: 0.75),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
