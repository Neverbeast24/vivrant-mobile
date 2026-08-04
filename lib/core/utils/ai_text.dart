/// Formats nested AI / coach payloads from the VIVRΛNT API into readable text.
String formatAiText(dynamic value, {List<String> preferKeys = const []}) {
  if (value == null) return '';
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();

  if (value is Map) {
    final map = Map<String, dynamic>.from(value);
    for (final key in preferKeys) {
      final nested = formatAiText(map[key], preferKeys: preferKeys);
      if (nested.isNotEmpty) return nested;
    }

    final title = map['title']?.toString().trim();
    final body = map['body']?.toString().trim() ??
        map['story']?.toString().trim() ??
        map['tip']?.toString().trim() ??
        map['advice']?.toString().trim() ??
        map['suggestion']?.toString().trim() ??
        map['summary']?.toString().trim() ??
        map['coaching']?.toString().trim();

    if (body != null && body.isNotEmpty && body != 'null') {
      if (body.startsWith('{') || body.startsWith('[')) {
        final nested = formatAiText(map['body'] ?? map['story'] ?? map['tip']);
        if (nested.isNotEmpty) {
          return (title != null && title.isNotEmpty && title != nested)
              ? '$title\n\n$nested'
              : nested;
        }
      }
      if (title != null && title.isNotEmpty && title != body) {
        return '$title\n\n$body';
      }
      return body;
    }

    // Nested objects under common keys.
    for (final key in [
      'coaching',
      'tip',
      'insight',
      'advice',
      'story',
      'suggestion',
      'summary',
      'swap',
    ]) {
      if (!map.containsKey(key)) continue;
      final nested = formatAiText(map[key]);
      if (nested.isNotEmpty) {
        if (title != null && title.isNotEmpty && title != nested) {
          return '$title\n\n$nested';
        }
        return nested;
      }
    }

    if (title != null && title.isNotEmpty) return title;
  }

  if (value is List) {
    final parts = value
        .map((e) => formatAiText(e))
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.join('\n');
  }

  final raw = value.toString();
  if (raw.startsWith('Instance of') || raw == 'null') return '';
  return raw;
}

/// Prefer body/title fields from a top-level API response map.
String formatAiResponse(
  Map<String, dynamic> res, {
  List<String> keys = const [
    'advice',
    'insight',
    'story',
    'suggestion',
    'summary',
    'tip',
    'coaching',
  ],
}) {
  for (final key in keys) {
    if (!res.containsKey(key)) continue;
    final text = formatAiText(res[key]);
    if (text.isNotEmpty) return text;
  }
  return formatAiText(res);
}
