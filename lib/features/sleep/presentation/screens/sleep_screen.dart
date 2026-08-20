import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../wellness/presentation/widgets/wellness_pulse_bar.dart';

class SleepScreen extends ConsumerStatefulWidget {
  const SleepScreen({super.key});

  @override
  ConsumerState<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends ConsumerState<SleepScreen> {
  final _hours = TextEditingController(text: '7');
  final _note = TextEditingController();
  int _quality = 3;
  bool _loading = false;
  Map<String, dynamic> _today = const {};

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final today = await ref.read(vivrantApiProvider).getToday();
      if (!mounted) return;
      setState(() => _today = today);
    } catch (_) {}
  }

  @override
  void dispose() {
    _hours.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final hours = double.tryParse(_hours.text) ?? 7;
      await ref.read(vivrantApiProvider).logSleep({
        'sleep_minutes': (hours * 60).round(),
        'sleep_quality': _quality,
        if (_note.text.trim().isNotEmpty) 'note': _note.text.trim(),
      });
      if (!mounted) return;
      context.showSuccess('Sleep logged');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _coach() async {
    try {
      final res = await ref.read(vivrantApiProvider).coachSleep();
      if (!mounted) return;
      context.showInfo(formatAiResponse(res, keys: const ['advice', 'coaching', 'tip']));
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Sleep')),
      child: ListView(
        padding: VivrantLayout.pagePadding,
        children: [
          const PageHeader(
            eyebrow: 'Rest',
            title: 'Sleep',
            highlight: 'log',
          ),
          if (_today.isNotEmpty) ...[
            WellnessPulseBar(today: _today, current: 'sleep'),
            const SectionGap(),
          ],
          VivrantPanel(
            title: 'Last night',
            child: Column(
              children: [
                TextField(
                  controller: _hours,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Hours slept'),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Quality: $_quality',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Slider(
                  value: _quality.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_quality',
                  onChanged: (v) => setState(() => _quality = v.round()),
                ),
                TextField(
                  controller: _note,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: Text(_loading ? 'Saving…' : 'Save sleep'),
                ),
              ],
            ),
          ),
          const SectionGap(),
          OutlinedButton.icon(
            onPressed: _coach,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Sleep coach'),
          ),
        ],
      ),
    );
  }
}
