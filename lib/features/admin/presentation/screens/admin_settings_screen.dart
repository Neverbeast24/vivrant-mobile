import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/providers/module_cache.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  final _title = TextEditingController();
  final _body = TextEditingController();

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<Map<String, dynamic>>(ModuleCacheKeys.adminSettings);
    if (cached != null) {
      _data = cached;
      _loading = false;
    }
    _load();
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final showSpinner = _data == null;
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final data = await ref.read(vivrantApiProvider).adminSettings();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.adminSettings, data);
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

  Future<void> _broadcast() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      context.showInfo('Title and message are required');
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await ref.read(vivrantApiProvider).adminBroadcast({
        'title': _title.text.trim(),
        'body': _body.text.trim(),
        'target': 'all',
      });
      if (!mounted) return;
      _title.clear();
      _body.clear();
      context.showSuccess(
        result['message']?.toString() ?? 'Broadcast sent',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = (_data?['services'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return GradientScaffold(
      appBar: AppBar(title: const Text('System')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Admin',
              title: 'System',
              highlight: 'settings',
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
            else ...[
              const SectionLabel('Broadcast notice'),
              VivrantPanel(
                child: Column(
                  children: [
                    TextField(
                      controller: _title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _body,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Message'),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: _sending ? 'Sending…' : 'Send to all members',
                      onPressed: _sending ? null : _broadcast,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Service health'),
              ...services.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VivrantPanel(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(service['name']?.toString() ?? ''),
                      subtitle: Text(service['detail']?.toString() ?? ''),
                      trailing: Icon(
                        service['ok'] == true
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        color: service['ok'] == true
                            ? Colors.green
                            : Colors.orange,
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
