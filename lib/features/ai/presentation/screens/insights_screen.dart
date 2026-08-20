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
  List<Map<String, dynamic>> _insights = [];
  bool _loading = true;
  bool _generating = false;
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
      final items = await ref.read(vivrantApiProvider).listInsights();
      if (!mounted) return;
      setState(() {
        _insights = items;
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

  Future<void> _generate() async {
    setState(() => _generating = true);
    try {
      await ref.read(vivrantApiProvider).generateInsight();
      if (!mounted) return;
      final items = await ref.read(vivrantApiProvider).listInsights();
      if (!mounted) return;
      setState(() {
        _insights = items;
        _error = null;
      });
      context.showSuccess('Insight generated');
    } catch (e) {
      if (!mounted) return;
      context.showError(apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  String _bodyOf(Map<String, dynamic> item) {
    final direct = item['body']?.toString();
    if (direct != null && direct.trim().isNotEmpty) return direct;
    return formatAiResponse(
      item,
      keys: const ['insight', 'summary', 'advice', 'body'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(title: const Text('Insights')),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: VivrantLayout.pagePadding,
          children: [
            const PageHeader(
              eyebrow: 'Ask for help',
              title: 'Saved',
              highlight: 'insights',
            ),
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_generating ? 'Generating…' : 'Generate insight'),
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
            else if (_insights.isEmpty)
              const EmptyState(
                message:
                    'No insights yet — generate your first recommendation.',
              )
            else
              ..._insights.map((item) {
                final title = item['title']?.toString() ?? 'Insight';
                final score = item['score'];
                final body = _bodyOf(item);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: VivrantPanel(
                    title: title,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (score != null)
                          Text(
                            'Score $score/100',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (body.isNotEmpty) ...[
                          if (score != null) const SizedBox(height: 8),
                          Text(body),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
