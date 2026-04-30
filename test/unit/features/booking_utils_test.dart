import 'package:discovaa/features/bookings/presentation/pages/booking_detail_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatBookingDate', () {
    test('formats date with AM correctly', () {
      final date = DateTime(2026, 4, 29, 10, 30);
      final result = formatBookingDate(date);
      expect(result, '4/29/2026, 10:30 AM');
    });

    test('formats date with PM correctly', () {
      final date = DateTime(2026, 4, 29, 15, 45);
      final result = formatBookingDate(date);
      expect(result, '4/29/2026, 3:45 PM');
    });

    test('formats date with 12 AM correctly', () {
      final date = DateTime(2026, 4, 29, 0, 15);
      final result = formatBookingDate(date);
      expect(result, '4/29/2026, 12:15 AM');
    });

    test('formats date with 12 PM correctly', () {
      final date = DateTime(2026, 4, 29, 12, 0);
      final result = formatBookingDate(date);
      expect(result, '4/29/2026, 12:00 PM');
    });

    test('pads single digit minutes with zero', () {
      final date = DateTime(2026, 4, 29, 9, 5);
      final result = formatBookingDate(date);
      expect(result, '4/29/2026, 9:05 AM');
    });
  });

  group('extractNumericPrice', () {
    test('extracts numeric price from NGN format', () {
      final result = extractNumericPrice('NGN 5,000');
      expect(result, '5000');
    });

    test('extracts numeric price with decimal', () {
      final result = extractNumericPrice('NGN 1,250.50');
      expect(result, '1250.50');
    });

    test('handles price without currency prefix', () {
      final result = extractNumericPrice('5,000');
      expect(result, '5000');
    });

    test('handles price without commas', () {
      final result = extractNumericPrice('NGN 5000');
      expect(result, '5000');
    });

    test('returns empty string for non-numeric input', () {
      final result = extractNumericPrice('Free');
      expect(result, '');
    });

    test('handles price with only decimal point', () {
      final result = extractNumericPrice('NGN 0.50');
      expect(result, '0.50');
    });
  });
}
