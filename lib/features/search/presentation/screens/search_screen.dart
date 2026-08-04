import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/vivrant_api.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _query.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _searched = true;
    });
    try {
      final data = await ref.read(vivrantApiProvider).search(q);
      if (!mounted) return;
      final raw = data['results'];
      final parsed = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            parsed.add(Map<String, dynamic>.from(item));
          }
        }
      }
      setState(() {
        _results = parsed;
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

  String? _mobileRouteForHref(String? href) {
    if (href == null || href.isEmpty) return null;
    final path = href.split('?').first;
    const map = <String, String>{
      '/dashboard': '/today',
      '/dashboard/nutrition': '/nutrition',
      '/dashboard/nutrition/log': '/nutrition/log',
      '/dashboard/movement': '/movement',
      '/dashboard/movement/log': '/movement/log',
      '/dashboard/gym': '/gym',
      '/dashboard/gym/plans': '/gym/plans',
      '/dashboard/gym/sessions': '/gym/sessions',
      '/dashboard/gym/machines': '/gym/machines',
      '/dashboard/gym/demos': '/gym/demos',
      '/dashboard/hydration': '/hydration',
      '/dashboard/sleep': '/sleep',
      '/dashboard/habits': '/habits',
      '/dashboard/mindfulness': '/mindfulness',
      '/dashboard/spending': '/spending',
      '/dashboard/pantry': '/pantry',
      '/dashboard/groceries': '/groceries',
      '/dashboard/ai': '/ai',
      '/dashboard/ai/reminders': '/ai/reminders',
      '/dashboard/ai/insights': '/ai/insights',
      '/dashboard/reports': '/reports',
      '/dashboard/settings': '/profile',
      '/dashboard/settings/goals': '/goals',
      '/dashboard/journal': '/journal',
    };
    return map[path];
  }

  @override
  Widget build(BuildContext context) {
    final byCategory = <String, List<Map<String, dynamic>>>{};
    for (final item in _results) {
      final category = (item['category']?.toString().trim().isNotEmpty == true)
          ? item['category'].toString()
          : 'results';
      byCategory.putIfAbsent(category, () => []).add(item);
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeader(
            eyebrow: 'Find',
            title: 'Search your',
            highlight: 'data',
          ),
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Meals, workouts, goals…',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: _search,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AsyncBody(
            loading: _loading,
            error: _error,
            onRetry: _search,
            child: !_searched
                ? const EmptyState(
                    message: 'Type a query to search across modules.',
                  )
                : _results.isEmpty
                    ? const EmptyState(message: 'No matches found.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final section in byCategory.entries) ...[
                            SectionLabel(
                              section.key.replaceAll('_', ' '),
                            ),
                            ...section.value.map((item) {
                              final title = item['label']?.toString() ??
                                  item['title']?.toString() ??
                                  item['meal_name']?.toString() ??
                                  item['name']?.toString() ??
                                  'Result';
                              final subtitle = item['detail']?.toString() ??
                                  item['category']?.toString();
                              final route =
                                  _mobileRouteForHref(item['href']?.toString());
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ListRow(
                                  leading:
                                      const IconWell(icon: Icons.search),
                                  title: title,
                                  subtitle: subtitle,
                                  onTap: route == null
                                      ? null
                                      : () => context.push(route),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
