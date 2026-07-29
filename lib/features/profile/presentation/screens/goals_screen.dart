import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  List<HealthGoal> _goals = [];
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
    _load();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final goals = await ref.read(vivrantApiProvider).listGoals();
      if (!mounted) return;
      setState(() {
        _goals = goals;
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New goal'),
        content: TextField(
          controller: title,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Title',
            hintText: 'e.g. Walk 8k steps',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true && title.text.trim().isNotEmpty && mounted) {
      try {
        await ref.read(vivrantApiProvider).addGoal({
          'title': title.text.trim(),
          'category': 'general',
          'status': 'active',
        });
        HapticFeedback.lightImpact();
        _load();
      } catch (e) {
        if (!mounted) return;
        context.showError(apiErrorMessage(e));
      }
    }
  }

  Color _statusColor(String status, bool dark) {
    switch (status) {
      case 'completed':
        return dark ? VivrantColors.darkCyan : VivrantColors.cyan;
      case 'active':
        return dark ? VivrantColors.darkAccent : VivrantColors.accent;
      default:
        return dark ? VivrantColors.darkMuted : VivrantColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;
    final panel = dark ? VivrantColors.darkPanel : Colors.white;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: [
          IconButton(
            onPressed: _add,
            tooltip: 'Add goal',
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
                eyebrow: 'Goals',
                title: 'Health',
                highlight: 'targets',
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
            else if (_goals.isEmpty)
              EmptyState(
                message: 'No goals yet. Set one to stay on track.',
                action: PrimaryButton(
                  label: 'Add goal',
                  onPressed: _add,
                  icon: Icons.flag_outlined,
                ),
              )
            else
              ...List.generate(_goals.length, (i) {
                final g = _goals[i];
                final start = (0.15 + i * 0.08).clamp(0.0, 0.7);
                final end = (start + 0.35).clamp(0.0, 1.0);
                final statusColor = _statusColor(g.status, dark);

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
                        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                        decoration: BoxDecoration(
                          color: panel.withValues(alpha: dark ? 0.92 : 0.96),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: ink.withValues(alpha: 0.06)),
                          boxShadow: [
                            BoxShadow(
                              color: VivrantColors.accent
                                  .withValues(alpha: dark ? 0.07 : 0.04),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                g.status == 'completed'
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.flag_outlined,
                                color: statusColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    g.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              statusColor.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          g.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        g.category,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: muted,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.more_horiz_rounded,
                                color: muted,
                              ),
                              onSelected: (v) async {
                                try {
                                  if (v == 'delete') {
                                    await ref
                                        .read(vivrantApiProvider)
                                        .deleteGoal(g.id);
                                  } else {
                                    await ref
                                        .read(vivrantApiProvider)
                                        .updateGoalStatus(g.id, v);
                                  }
                                  HapticFeedback.selectionClick();
                                  _load();
                                } catch (e) {
                                  if (!mounted) return;
                                  context.showError(apiErrorMessage(e));
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'active',
                                  child: Text('Mark active'),
                                ),
                                PopupMenuItem(
                                  value: 'completed',
                                  child: Text('Mark completed'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
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
