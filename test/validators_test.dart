import 'package:flutter_test/flutter_test.dart';
import 'package:vivrant_mobile/core/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('requires value', () {
      expect(validateEmail(null), 'Email is required');
      expect(validateEmail(''), 'Email is required');
    });

    test('rejects invalid emails', () {
      expect(validateEmail('not-an-email'), 'Enter a valid email');
      expect(validateEmail('a@b'), 'Enter a valid email');
    });

    test('accepts valid emails', () {
      expect(validateEmail('member@vivrant.app'), isNull);
    });
  });

  group('validatePassword', () {
    test('requires value and min length', () {
      expect(validatePassword(null), 'Password is required');
      expect(validatePassword('short'), contains('at least 8'));
      expect(validatePassword('longenough'), isNull);
    });
  });
}
