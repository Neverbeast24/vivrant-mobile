import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _canManageRoles = false;
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
      final data = await ref.read(vivrantApiProvider).adminUsers();
      if (!mounted) return;
      setState(() {
        _users = (data['users'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _canManageRoles = data['canManageRoles'] == true;
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

  Future<void> _patch(String userId, Map<String, dynamic> body) async {
    try {
      await ref.read(vivrantApiProvider).adminUpdateUser(userId, body);
      await _load();
      if (!mounted) return;
      context.showSuccess('User updated');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  Future<void> _edit(Map<String, dynamic> user) async {
    var role = user['role']?.toString() ?? 'user';
    var status = user['status']?.toString() ?? 'active';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(user['display_name']?.toString() ?? 'User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canManageRoles)
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'super_admin',
                      child: Text('Super Admin'),
                    ),
                  ],
                  onChanged: (v) => setLocal(() => role = v ?? role),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                    value: 'suspended',
                    child: Text('Suspended'),
                  ),
                ],
                onChanged: (v) => setLocal(() => status = v ?? status),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final body = <String, dynamic>{'status': status};
    if (_canManageRoles) body['role'] = role;
    await _patch(user['user_id'].toString(), body);
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Users')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const PageHeader(
              eyebrow: 'Admin',
              title: 'User',
              highlight: 'management',
            ),
            if (_error != null)
              EmptyState(
                message: _error!,
                action: OutlinedButton(
                  onPressed: _load,
                  child: const Text('Retry'),
                ),
              )
            else if (_loading)
              const LoadingView()
            else if (_users.isEmpty)
              const EmptyState(message: 'No users found.')
            else
              ..._users.map(
                (user) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(user['display_name']?.toString() ?? 'Member'),
                      subtitle: Text(
                        '${user['email'] ?? '—'}\n'
                        '${user['role'] ?? 'user'} · ${user['status'] ?? 'active'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _edit(user),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
