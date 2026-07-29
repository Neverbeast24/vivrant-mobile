import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/vivrant_colors.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class MindfulnessScreen extends ConsumerStatefulWidget {
  const MindfulnessScreen({super.key});

  @override
  ConsumerState<MindfulnessScreen> createState() => _MindfulnessScreenState();
}

class _MindfulnessScreenState extends ConsumerState<MindfulnessScreen> {
  int _mood = 3;
  final _note = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).logMood(
            _mood,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      context.showSuccess('Mood saved');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _coach() async {
    try {
      final res = await ref.read(vivrantApiProvider).coachMindfulness();
      if (!mounted) return;
      context.showInfo(res['advice']?.toString() ?? res.toString());
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Mindfulness')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            eyebrow: 'Calm',
            title: 'How are you',
            highlight: 'feeling?',
          ),
          VivrantPanel(
            title: 'Mood (1–5)',
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (i) {
                    final n = i + 1;
                    final selected = _mood == n;
                    return ChoiceChip(
                      label: Text('$n'),
                      selected: selected,
                      selectedColor: VivrantColors.accentSoft,
                      onSelected: (_) => setState(() => _mood = n),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: Text(_loading ? 'Saving…' : 'Save mood'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _coach,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Mindfulness coach'),
          ),
        ],
      ),
    );
  }
}
