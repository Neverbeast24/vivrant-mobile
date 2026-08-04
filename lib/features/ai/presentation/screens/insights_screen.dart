import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/ai_text.dart';
import '../../../../core/utils/context_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _insight;
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final res = await ref.read(vivrantApiProvider).generateInsight();
      if (!mounted) return;
      setState(() {
        _insight = formatAiResponse(
          res,
          keys: const ['insight', 'summary', 'advice'],
        );
      });
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
      appBar: AppBar(title: const Text('Insights')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            eyebrow: 'AI',
            title: 'Personal',
            highlight: 'insight',
          ),
          ElevatedButton.icon(
            onPressed: _loading ? null : _generate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(_loading ? 'Generating…' : 'Generate insight'),
          ),
          if (_insight != null) ...[
            const SizedBox(height: 16),
            VivrantPanel(
              title: 'For you',
              child: Text(_insight!),
            ),
          ],
        ],
      ),
    );
  }
}
