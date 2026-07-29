import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';
import '../../../../shared/constants/enums.dart';

class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  final _title = TextEditingController();
  final _minutes = TextEditingController();
  final _calories = TextEditingController();
  String _type = 'walk';
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _minutes.dispose();
    _calories.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(vivrantApiProvider).logWorkout({
        'title': _title.text.trim(),
        'activity_type': _type,
        if (_minutes.text.isNotEmpty)
          'duration_minutes': int.tryParse(_minutes.text),
        if (_calories.text.isNotEmpty)
          'calories_burned': double.tryParse(_calories.text),
      });
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Log workout')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [
              for (final t in activityTypes)
                DropdownMenuItem(value: t, child: Text(labelForOption(t))),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'other'),
            decoration: const InputDecoration(labelText: 'Activity type'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration (minutes)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories burned'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: Text(_loading ? 'Saving…' : 'Save workout'),
          ),
        ],
      ),
    );
  }
}
