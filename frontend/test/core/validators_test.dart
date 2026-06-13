import 'package:flutter_test/flutter_test.dart';
import 'package:harfidar/core/utils/validators.dart';

void main() {
  group('AppValidators.email', () {
    test('returns null for valid email', () {
      expect(AppValidators.email('test@example.com'), isNull);
      expect(AppValidators.email('user.name+tag@domain.co.dz'), isNull);
    });

    test('returns error for empty email', () {
      expect(AppValidators.email(''), isNotNull);
      expect(AppValidators.email(null), isNotNull);
    });

    test('returns error for invalid email format', () {
      expect(AppValidators.email('notanemail'), isNotNull);
      expect(AppValidators.email('missing@'), isNotNull);
      expect(AppValidators.email('@nodomain.com'), isNotNull);
    });
  });

  group('AppValidators.password', () {
    test('returns null for valid password', () {
      expect(AppValidators.password('Password@123'), isNull);
      expect(AppValidators.password('StrongPass1'), isNull);
    });

    test('returns error for empty password', () {
      expect(AppValidators.password(''), isNotNull);
      expect(AppValidators.password(null), isNotNull);
    });

    test('returns error for password shorter than 8 chars', () {
      expect(AppValidators.password('Pass1'), isNotNull);
    });

    test('returns error for password without uppercase', () {
      expect(AppValidators.password('password1'), isNotNull);
    });

    test('returns error for password without lowercase', () {
      expect(AppValidators.password('PASSWORD1'), isNotNull);
    });

    test('returns error for password without number', () {
      expect(AppValidators.password('PasswordOnly'), isNotNull);
    });
  });

  group('AppValidators.phone', () {
    test('returns null for valid Algerian phone', () {
      expect(AppValidators.phone('+213555123456'), isNull);
      expect(AppValidators.phone('0555123456'), isNull);
      expect(AppValidators.phone(null), isNull);   // optional field
      expect(AppValidators.phone(''), isNull);     // optional field
    });

    test('returns error for invalid phone', () {
      expect(AppValidators.phone('123'), isNotNull);
      expect(AppValidators.phone('abcdefghij'), isNotNull);
    });
  });

  group('AppValidators.required', () {
    test('returns null for non-empty value', () {
      expect(AppValidators.required('hello'), isNull);
      expect(AppValidators.required('  valid  '), isNull);
    });

    test('returns error for null or empty value', () {
      expect(AppValidators.required(null), isNotNull);
      expect(AppValidators.required(''), isNotNull);
      expect(AppValidators.required('   '), isNotNull);
    });

    test('includes field name in error message', () {
      final error = AppValidators.required(null, 'البريد الإلكتروني');
      expect(error, contains('البريد الإلكتروني'));
    });
  });

  group('AppValidators.minLength', () {
    test('returns null when value meets minimum length', () {
      expect(AppValidators.minLength('hello', 3), isNull);
      expect(AppValidators.minLength('hello', 5), isNull);
    });

    test('returns error when value is shorter than minimum', () {
      expect(AppValidators.minLength('hi', 5), isNotNull);
      expect(AppValidators.minLength(null, 3), isNotNull);
    });
  });
}
