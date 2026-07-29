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
  Map<String, dynamic>? _results;
  bool _loading = false;
  String? _error;

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
    });
    try {
      final data = await ref.read(vivrantApiProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = data;
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

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<dynamic>>{};
    if (_results != null) {
      for (final entry in _results!.entries) {
        if (entry.value is List) {
          sections[entry.key] = entry.value as List;
        }
      }
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
            child: sections.isEmpty
                ? EmptyState(
                    message: _results == null
                        ? 'Type a query to search across modules.'
                        : 'No matches found.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in sections.entries) ...[
                        SectionLabel(section.key.replaceAll('_', ' ')),
                        ...section.value.map((raw) {
                          final item = Map<String, dynamic>.from(raw as Map);
                          final title = item['title']?.toString() ??
                              item['meal_name']?.toString() ??
                              item['name']?.toString() ??
                              'Result';
                          final subtitle = item['href']?.toString() ??
                              item['category']?.toString();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListRow(
                              leading: const IconWell(icon: Icons.search),
                              title: title,
                              subtitle: subtitle,
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
