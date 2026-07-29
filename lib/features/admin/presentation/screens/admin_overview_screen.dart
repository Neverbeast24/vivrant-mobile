import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class AdminOverviewScreen extends ConsumerStatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  ConsumerState<AdminOverviewScreen> createState() =>
      _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends ConsumerState<AdminOverviewScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(vivrantApiProvider).adminOverview();
      if (!mounted) return;
      setState(() {
        _data = data;
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

  int _c(String key) =>
      ((_data?['counts'] as Map?)?[key] as num?)?.toInt() ?? 0;

  @override
  Widget build(BuildContext context) {
    final isSuper = _data?['isSuperAdmin'] == true;
    final recentUsers = (_data?['recentUsers'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Admin')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            PageHeader(
              eyebrow: isSuper ? 'Super Admin' : 'Admin',
              title: 'Platform',
              highlight: 'pulse',
            ),
            if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _Stat('Users', _loading ? '—' : '${_c('users')}'),
                  _Stat('Staff', _loading ? '—' : '${_c('staff')}'),
                  _Stat('Suspended', _loading ? '—' : '${_c('suspended')}'),
                  _Stat('Tickets', _loading ? '—' : '${_c('openTickets')}'),
                  if (isSuper)
                    _Stat(
                      'Inquiries',
                      _loading ? '—' : '${_c('openInquiries')}',
                    ),
                  _Stat('Audit', _loading ? '—' : '${_c('auditLogs')}'),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Console'),
              ModuleTile(
                icon: Icons.people_outline,
                label: 'Users',
                caption: 'Roles and account status',
                onTap: () => context.push('/admin/users'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.support_agent_outlined,
                label: 'Tickets',
                caption: 'Open support inbox',
                onTap: () => context.push('/admin/tickets'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.shield_outlined,
                label: 'Permissions',
                caption: 'Role access matrix',
                onTap: () => context.push('/admin/roles'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.receipt_long_outlined,
                label: 'Audit logs',
                caption: 'Platform action history',
                onTap: () => context.push('/admin/audit'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.settings_suggest_outlined,
                label: 'System',
                caption: 'Health & broadcast',
                onTap: () => context.push('/admin/settings'),
              ),
              if (isSuper) ...[
                const SizedBox(height: 10),
                ModuleTile(
                  icon: Icons.travel_explore_outlined,
                  label: 'Member activity',
                  caption: 'Cross-module logs',
                  onTap: () => context.push('/admin/activity'),
                ),
                const SizedBox(height: 10),
                ModuleTile(
                  icon: Icons.inbox_outlined,
                  label: 'Inquiries',
                  caption: 'Plus & Campus requests',
                  onTap: () => context.push('/admin/inquiries'),
                ),
              ],
              const SizedBox(height: 24),
              const SectionLabel('Recent members'),
              if (_loading)
                const LoadingView()
              else if (recentUsers.isEmpty)
                const EmptyState(message: 'No members yet.')
              else
                ...recentUsers.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: VivrantPanel(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(user['display_name']?.toString() ?? 'Member'),
                        subtitle: Text(
                          '${user['role'] ?? 'user'} · ${user['status'] ?? 'active'}',
                        ),
                      ),
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: VivrantPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
