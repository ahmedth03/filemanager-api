import 'package:flutter_test/flutter_test.dart';
import 'package:harfidar/core/utils/formatters.dart';

void main() {
  group('AppFormatters.formatPrice', () {
    test('formats whole number price with DA currency', () {
      final result = AppFormatters.formatPrice(50000);
      expect(result, contains('DA'));
      expect(result, contains('50'));
    });

    test('formats zero price', () {
      final result = AppFormatters.formatPrice(0);
      expect(result, contains('0'));
    });

    test('accepts custom currency', () {
      final result = AppFormatters.formatPrice(1000, currency: 'DZD');
      expect(result, contains('DZD'));
    });
  });

  group('AppFormatters.formatRating', () {
    test('formats rating to 1 decimal place', () {
      expect(AppFormatters.formatRating(4.5), equals('4.5'));
      expect(AppFormatters.formatRating(3.0), equals('3.0'));
      expect(AppFormatters.formatRating(4.75), equals('4.8'));
    });
  });

  group('AppFormatters.formatCount', () {
    test('formats counts under 1000 as-is', () {
      expect(AppFormatters.formatCount(500), equals('500'));
      expect(AppFormatters.formatCount(999), equals('999'));
    });

    test('formats thousands with K suffix', () {
      expect(AppFormatters.formatCount(1000), contains('K'));
      expect(AppFormatters.formatCount(2500), contains('K'));
    });

    test('formats millions with M suffix', () {
      expect(AppFormatters.formatCount(1000000), contains('M'));
    });
  });

  group('AppFormatters.timeAgo', () {
    test('returns "الآن" for very recent date', () {
      final now = DateTime.now();
      final result = AppFormatters.timeAgo(now);
      expect(result, equals('الآن'));
    });

    test('returns minutes for recent date', () {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      final result = AppFormatters.timeAgo(fiveMinutesAgo);
      expect(result, contains('5'));
    });

    test('returns hours for older date', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      final result = AppFormatters.timeAgo(twoHoursAgo);
      expect(result, contains('2'));
    });

    test('returns formatted date for old date', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 60));
      final result = AppFormatters.timeAgo(oldDate);
      // Should return formatted date, not relative time
      expect(result.length, greaterThan(3));
    });
  });
}
