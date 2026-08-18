import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../widgets/wellness_pulse_bar.dart';

/// Sleep + hydration + mood on one daily check-in (mirrors web Wellness hub).
class WellnessHubScreen extends ConsumerStatefulWidget {
  const WellnessHubScreen({super.key});

  @override
  ConsumerState<WellnessHubScreen> createState() => _WellnessHubScreenState();
}

class _WellnessHubScreenState extends ConsumerState<WellnessHubScreen> {
  Map<String, dynamic> _today = const {};
  bool _loading = true;
  String? _error;
  bool _busy = false;
  int _mood = 4;
  final _hours = TextEditingController(text: '7');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hours.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = await ref.read(vivrantApiProvider).getToday();
      if (!mounted) return;
      final checkin = today['checkin'] is Map
          ? Map<String, dynamic>.from(today['checkin'] as Map)
          : const <String, dynamic>{};
      final sleepMin = (checkin['sleep_minutes'] as num?)?.toDouble();
      final mood = (checkin['mood'] as num?)?.toInt();
      setState(() {
        _today = today;
        if (sleepMin != null) {
          _hours.text = (sleepMin / 60).toStringAsFixed(1);
        }
        if (mood != null) _mood = mood;
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

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      context.showSuccess(ok);
      await _load();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final checkin = _today['checkin'] is Map
        ? Map<String, dynamic>.from(_today['checkin'] as Map)
        : const <String, dynamic>{};
    final waterMl = (_today['water_ml'] as num?)?.toInt() ??
        (checkin['water_ml'] as num?)?.toInt() ??
        0;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Wellness'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              eyebrow: 'Wellness',
              title: 'Body signals,',
              highlight: 'one place',
            ),
            Text(
              'Sleep, water, and mood share one daily check-in.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
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
            else ...[
              WellnessPulseBar(today: _today),
              const SizedBox(height: 16),
              VivrantPanel(
                title: 'Log sleep',
                child: Column(
                  children: [
                    TextField(
                      controller: _hours,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Hours last night'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              final hours = double.tryParse(_hours.text) ?? 7;
                              _run(
                                () => ref.read(vivrantApiProvider).logSleep({
                                  'sleep_minutes': (hours * 60).round(),
                                }),
                                'Sleep logged',
                              );
                            },
                      child: const Text('Save sleep'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              VivrantPanel(
                title: 'Add water · $waterMl ml today',
                child: Wrap(
                  spacing: 8,
                  children: [
                    for (final ml in [250, 500, 750])
                      ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () => _run(
                                  () => ref
                                      .read(vivrantApiProvider)
                                      .addHydration(ml),
                                  '+$ml ml',
                                ),
                        child: Text('+$ml ml'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              VivrantPanel(
                title: 'Mood',
                child: Column(
                  children: [
                    ScorePicker(
                      value: _mood,
                      onChanged: (v) => setState(() => _mood = v),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _busy
                          ? null
                          : () => _run(
                                () => ref
                                    .read(vivrantApiProvider)
                                    .logMood(_mood),
                                'Mood saved',
                              ),
                      child: const Text('Save mood'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ModuleTile(
                icon: Icons.nightlight_round,
                label: 'Sleep',
                caption: 'History & coach',
                onTap: () => context.push('/sleep'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.water_drop_outlined,
                label: 'Hydration',
                caption: 'Water goals',
                onTap: () => context.push('/hydration'),
              ),
              const SizedBox(height: 10),
              ModuleTile(
                icon: Icons.air,
                label: 'Mindfulness',
                caption: 'Mood & calm',
                onTap: () => context.push('/mindfulness'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
