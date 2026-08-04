import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/utils/ai_text.dart';

void main() {
  group('formatAiText', () {
    test('returns trimmed strings', () {
      expect(formatAiText('  hello  '), 'hello');
    });

    test('formats nested coaching objects', () {
      final text = formatAiText({
        'title': 'Rest well',
        'body': 'Aim for 7–8 hours tonight.',
        'score': 0.8,
      });
      expect(text, contains('Rest well'));
      expect(text, contains('Aim for 7–8 hours'));
    });

    test('unwraps tip objects', () {
      final text = formatAiText({
        'tip': {'title': 'Breathe', 'body': 'Try a 4-7-8 cycle.'},
      });
      expect(text, contains('Breathe'));
      expect(text, contains('4-7-8'));
    });
  });

  group('formatAiResponse', () {
    test('prefers insight object over raw map dump', () {
      final text = formatAiResponse({
        'ok': true,
        'insight': {
          'title': 'Consistency',
          'body': 'You logged meals 5 days this week.',
        },
      });
      expect(text, isNot(contains('Instance of')));
      expect(text, contains('Consistency'));
      expect(text, contains('logged meals'));
    });

    test('formats weekly story payload', () {
      final text = formatAiResponse({
        'story': {
          'title': 'Your week',
          'story': 'Hydration improved and steps rose.',
          'focuses': ['water', 'walks'],
        },
      }, keys: const ['story']);
      expect(text, contains('Your week'));
      expect(text, contains('Hydration improved'));
    });
  });
}
