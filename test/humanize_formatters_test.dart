import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/utils/formatters.dart';
import 'package:vivrant_mobile/core/utils/humanize.dart';

void main() {
  group('humanizeLabel', () {
    test('converts snake_case keys', () {
      expect(humanizeLabel('lower_back'), 'Lower Back');
      expect(humanizeLabel('protein_g'), 'Protein G');
    });
  });

  group('formatCurrency', () {
    test('formats peso amounts', () {
      expect(formatCurrency(1250), '₱1,250');
      expect(formatCurrency(99.5), '₱99.5');
    });
  });

  group('formatDate', () {
    test('formats dates', () {
      final d = DateTime(2026, 8, 4);
      expect(formatShortDate(d), 'Aug 4');
      expect(formatDate(d), 'Aug 4, 2026');
    });
  });
}
