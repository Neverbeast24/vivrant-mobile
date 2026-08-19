import 'package:flutter_test/flutter_test.dart';

import 'package:vivrant_mobile/core/utils/list_order.dart';

void main() {
  test('applyIdOrder puts known ids first', () {
    final items = [1, 2, 3];
    expect(applyIdOrder(items, [3, 1], (id) => id), [3, 1, 2]);
  });

  test('parseModuleListOrder reads positive ids', () {
    expect(
      parseModuleListOrder({
        'list_order': {
          'habits': [2, '3', 0, -1],
          'meals': [9],
        },
      }, 'habits'),
      [2, 3],
    );
  });

  test('moveItem and normalizeReorderIndex match Flutter reorder', () {
    expect(moveItem(['a', 'b', 'c', 'd'], 0, 2), ['b', 'c', 'a', 'd']);
    expect(normalizeReorderIndex(0, 3), 2);
  });
}
