import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';
import '../../../../shared/providers/shell_tab_provider.dart';
import '../widgets/chat_bubble.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  static const _tabIndex = 3;

  List<AiChatMessage> _messages = [];
  final _input = TextEditingController();
  bool _loading = false;
  bool _activated = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<AiChatMessage>>(ModuleCacheKeys.aiChat);
    if (cached != null) {
      _messages = List<AiChatMessage>.from(cached);
      _loading = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeActivate());
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _maybeActivate() {
    if (!mounted || _activated) return;
    if (ref.read(shellTabIndexProvider) != _tabIndex) return;
    _activated = true;
    _load();
  }

  Future<void> _load() async {
    final showSpinner = ref.read(moduleCacheProvider).shouldShowSpinner(ModuleCacheKeys.aiChat);
    setState(() {
      if (showSpinner) _loading = true;
      _error = null;
    });
    try {
      final messages = await ref.read(vivrantApiProvider).chatHistory();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.aiChat, messages);
      setState(() {
        _messages = messages;
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

  Future<void> _send() async {
    final q = _input.text.trim();
    if (q.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final reply = await ref.read(vivrantApiProvider).askAi(q);
      if (!mounted) return;
      final updated = [
        ..._messages,
        AiChatMessage(id: -1, role: 'user', content: q),
        reply,
      ];
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.aiChat, updated);
      setState(() => _messages = updated);
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shellTabIndexProvider, (_, next) {
      if (next == _tabIndex) _maybeActivate();
    });
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: PageHeader(
              eyebrow: 'Viva',
              title: 'Ask',
              highlight: 'anything',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => context.push('/ai/insights'),
                    icon: const Icon(Icons.insights_outlined),
                  ),
                  IconButton(
                    onPressed: () => context.push('/ai/reminders'),
                    icon: const Icon(Icons.alarm_outlined),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: !_activated || _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: EmptyState(
                          message: _error!,
                          action: OutlinedButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ),
                      )
                    : _messages.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: EmptyState(
                              message:
                                  'Ask Viva about nutrition, movement, or recovery.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) {
                                final m = _messages[i];
                                return ChatBubble(
                                  content: m.content,
                                  isUser: m.isUser,
                                );
                              },
                            ),
                          ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(
                      hintText: 'Ask Viva…',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
