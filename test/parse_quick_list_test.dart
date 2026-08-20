import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/utils/parse_quick_list.dart';

void main() {
  group('parseSpreadsheetPaste', () {
    test('parses one name per line', () {
      expect(parseSpreadsheetPaste('eggs\nmilk\n\nrice'), [
        ['eggs'],
        ['milk'],
        ['rice'],
      ]);
    });

    test('parses tab-separated Excel paste and skips a header', () {
      const text = 'Name\tQty\tPrice\neggs\t1 tray\t180\nmilk\t1 L\t90';
      expect(parseSpreadsheetPaste(text), [
        ['eggs', '1 tray', '180'],
        ['milk', '1 L', '90'],
      ]);
    });

    test('parses comma lists when most lines have commas', () {
      expect(parseSpreadsheetPaste('eggs, 1 tray, 180\nmilk, 1L'), [
        ['eggs', '1 tray', '180'],
        ['milk', '1L'],
      ]);
    });

    test('keeps commas inside quoted cells', () {
      expect(
        parseSpreadsheetPaste('"Eggs, dozen", protein\nmilk, dairy'),
        [
          ['Eggs, dozen', 'protein'],
          ['milk', 'dairy'],
        ],
      );
    });

    test('caps rows', () {
      final text = List.generate(60, (i) => 'item ${i + 1}').join('\n');
      expect(parseSpreadsheetPaste(text, maxRows: 40), hasLength(40));
    });
  });

  group('mapTypedLine', () {
    test('maps name, quantity, category, and price', () {
      final row = mapTypedLine(
        ['Purefoods hotdog', '1 pack', 'protein', '159'],
        ['protein', 'produce'],
      );
      expect(row.name, 'Purefoods hotdog');
      expect(row.quantity, '1 pack');
      expect(row.category, 'protein');
      expect(row.amount, 159);
    });

    test('treats a lone number as amount', () {
      final row = mapTypedLine(['milk', '90'], ['dairy']);
      expect(row.name, 'milk');
      expect(row.quantity, isNull);
      expect(row.category, isNull);
      expect(row.amount, 90);
    });
  });

  group('asNumber', () {
    test('strips peso formatting', () {
      expect(asNumber('₱1,200'), 1200);
    });
  });
}
