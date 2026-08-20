import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/providers/module_cache.dart';

/// Journal directory — compose and history live on their own pages.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  int _count = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = ref
        .read(moduleCacheProvider)
        .read<List<JournalEntry>>(ModuleCacheKeys.journal);
    if (cached != null) {
      _count = cached.length;
      _loading = false;
    }
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await ref.read(vivrantApiProvider).listJournal();
      if (!mounted) return;
      ref.read(moduleCacheProvider).write(ModuleCacheKeys.journal, entries);
      setState(() {
        _count = entries.length;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _reflect() async {
    try {
      final res = await ref.read(vivrantApiProvider).reflectJournal();
      if (!mounted) return;
      context.showInfo(
        formatAiResponse(
          res,
          keys: const ['reflection', 'tip', 'insight', 'advice'],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Journal')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Reflect',
              title: 'Your',
              highlight: 'journal',
            ),
            Text(
              'Write on one page. Browse past notes on another.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SectionGap(),
            ...staggerAppear([
              ModuleTile(
                icon: Icons.edit_note_rounded,
                label: 'New entry',
                caption: 'Write a note for today',
                onTap: () => context.push('/journal/new').then((_) {
                  if (mounted) _load();
                }),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.menu_book_outlined,
                label: 'Past notes',
                caption: _loading
                    ? 'Your entries'
                    : _count == 0
                        ? 'Nothing saved yet'
                        : '$_count ${_count == 1 ? 'note' : 'notes'}',
                onTap: () => context.push('/journal/history'),
              ),
              const TileGap(),
              ModuleTile(
                icon: Icons.auto_awesome,
                label: 'Reflect with AI',
                caption: 'A short read of recent notes',
                onTap: _reflect,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
