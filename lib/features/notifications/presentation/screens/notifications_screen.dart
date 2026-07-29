import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _query = TextEditingController();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<AppNotification>>(ModuleCacheKeys.notifications);
    if (cached != null) {
      _items = List<AppNotification>.from(cached);
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<AppNotification> get _filtered {
    final q = _query.text.trim().toLowerCase();
    return _items.where((n) {
      if (_filter == 'unread' && n.isRead) return false;
      if (_filter == 'read' && !n.isRead) return false;
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) ||
          (n.body?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.notifications);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(vivrantApiProvider).listNotifications();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.notifications, items);
      setState(() {
        _items = items;
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

  Future<void> _markAll() async {
    try {
      await ref.read(vivrantApiProvider).markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        _items = [
          for (final n in _items)
            AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              createdAt: n.createdAt,
              isRead: true,
              href: n.href,
            ),
        ];
      });
      ref
          .read(moduleCacheProvider)
          .write(ModuleCacheKeys.notifications, _items);
      context.showSuccess('All notifications marked as read');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _markRead(AppNotification n) async {
    if (n.isRead) return;
    try {
      await ref.read(vivrantApiProvider).markNotificationRead(n.id);
      if (!mounted) return;
      setState(() {
        _items = [
          for (final item in _items)
            if (item.id == n.id)
              AppNotification(
                id: item.id,
                title: item.title,
                body: item.body,
                createdAt: item.createdAt,
                isRead: true,
                href: item.href,
              )
            else
              item,
        ];
      });
      ref
          .read(moduleCacheProvider)
          .write(ModuleCacheKeys.notifications, _items);
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unread = _items.where((n) => !n.isRead).length;
    final filtered = _filtered;
    final ink = dark ? VivrantColors.darkInk : VivrantColors.ink;
    final muted = dark ? VivrantColors.darkMuted : VivrantColors.muted;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAll,
              child: Text(
                'Mark all',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            PageHeader(
              eyebrow: 'Inbox',
              title: 'Updates',
              highlight: unread > 0 ? '($unread)' : null,
            ),
            if (unread > 0) ...[
              const SizedBox(height: 4),
              Text(
                '$unread unread',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 12),
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
            else if (_items.isEmpty)
              EmptyState(
                message: 'You’re all caught up — no notifications yet.',
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Refresh'),
                ),
              )
            else ...[
              VivrantSearchField(
                controller: _query,
                hintText: 'Search notifications…',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              VivrantFilterChips<String>(
                options: [
                  VivrantFilterOption(
                    value: 'all',
                    label: 'All',
                    count: _items.length,
                  ),
                  VivrantFilterOption(
                    value: 'unread',
                    label: 'Unread',
                    count: unread,
                  ),
                  VivrantFilterOption(
                    value: 'read',
                    label: 'Read',
                    count: _items.length - unread,
                  ),
                ],
                selected: _filter,
                onSelected: (v) => setState(() => _filter = v),
              ),
              const SizedBox(height: 16),
              if (filtered.isEmpty)
                const EmptyState(
                  message:
                      'No notifications match these filters. Try All or another search.',
                )
              else
                ...filtered.map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationCard(
                      notification: n,
                      ink: ink,
                      muted: muted,
                      dark: dark,
                      onTap: () => _markRead(n),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.ink,
    required this.muted,
    required this.dark,
    required this.onTap,
  });

  final AppNotification notification;
  final Color ink;
  final Color muted;
  final bool dark;
  final VoidCallback onTap;

  IconData get _icon {
    final title = notification.title.toLowerCase();
    final body = (notification.body ?? '').toLowerCase();
    final hay = '$title $body';
    if (hay.contains('goal')) return Icons.flag_rounded;
    if (hay.contains('habit') || hay.contains('streak')) {
      return Icons.local_fire_department_rounded;
    }
    if (hay.contains('workout') || hay.contains('gym') || hay.contains('move')) {
      return Icons.fitness_center_rounded;
    }
    if (hay.contains('meal') || hay.contains('nutrition') || hay.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (hay.contains('sleep')) return Icons.bedtime_rounded;
    if (hay.contains('water') || hay.contains('hydrat')) {
      return Icons.water_drop_rounded;
    }
    if (hay.contains('remind')) return Icons.alarm_rounded;
    if (hay.contains('budget') || hay.contains('spend')) {
      return Icons.account_balance_wallet_rounded;
    }
    return Icons.notifications_rounded;
  }

  String? get _timeLabel {
    final created = notification.createdAt;
    if (created == null) return null;
    final now = DateTime.now();
    final diff = now.difference(created);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(created);
  }

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    final accent = dark ? VivrantColors.darkAccent : VivrantColors.accent;
    final card = dark ? VivrantColors.darkCard : VivrantColors.panel;
    final soft = dark ? VivrantColors.darkAccentSoft : VivrantColors.accentSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unread ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: unread ? soft.withValues(alpha: dark ? 0.55 : 0.65) : card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? accent.withValues(alpha: 0.28)
                  : ink.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: unread
                        ? accent.withValues(alpha: dark ? 0.22 : 0.12)
                        : (dark
                            ? VivrantColors.darkSurfaceSoft
                            : VivrantColors.surfaceSoft),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _icon,
                    color: unread ? accent : muted,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight:
                                    unread ? FontWeight.w800 : FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                          if (unread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(top: 5, left: 8),
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (notification.body != null &&
                          notification.body!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.body!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            height: 1.4,
                            color: muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      if (_timeLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _timeLabel!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: muted.withValues(alpha: 0.85),
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
  }
}
