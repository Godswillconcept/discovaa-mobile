import 'package:discovaa/features/bookings/data/models/booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookingStatus Transition Validation', () {
    group('canTransitionTo()', () {
      test('REQUESTED can transition to CONFIRMED', () {
        expect(
          BookingStatus.requested.canTransitionTo(BookingStatus.confirmed),
          isTrue,
        );
      });

      test('REQUESTED can transition to CANCELLED', () {
        expect(
          BookingStatus.requested.canTransitionTo(BookingStatus.cancelled),
          isTrue,
        );
      });

      test('REQUESTED cannot transition to COMPLETED', () {
        expect(
          BookingStatus.requested.canTransitionTo(BookingStatus.completed),
          isFalse,
        );
      });

      test('CONFIRMED can transition to COMPLETED', () {
        expect(
          BookingStatus.confirmed.canTransitionTo(BookingStatus.completed),
          isTrue,
        );
      });

      test('CONFIRMED can transition to CANCELLED', () {
        expect(
          BookingStatus.confirmed.canTransitionTo(BookingStatus.cancelled),
          isTrue,
        );
      });

      test('CONFIRMED cannot transition to REQUESTED', () {
        expect(
          BookingStatus.confirmed.canTransitionTo(BookingStatus.requested),
          isFalse,
        );
      });

      test('COMPLETED cannot transition to any status', () {
        expect(
          BookingStatus.completed.canTransitionTo(BookingStatus.requested),
          isFalse,
        );
        expect(
          BookingStatus.completed.canTransitionTo(BookingStatus.confirmed),
          isFalse,
        );
        expect(
          BookingStatus.completed.canTransitionTo(BookingStatus.cancelled),
          isFalse,
        );
      });

      test('CANCELLED cannot transition to any status', () {
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.requested),
          isFalse,
        );
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.confirmed),
          isFalse,
        );
        expect(
          BookingStatus.cancelled.canTransitionTo(BookingStatus.completed),
          isFalse,
        );
      });

      test('ONGOING can transition to COMPLETED or CANCELLED', () {
        expect(
          BookingStatus.ongoing.canTransitionTo(BookingStatus.completed),
          isTrue,
        );
        expect(
          BookingStatus.ongoing.canTransitionTo(BookingStatus.cancelled),
          isTrue,
        );
        expect(
          BookingStatus.ongoing.canTransitionTo(BookingStatus.requested),
          isFalse,
        );
      });
    });

    group('validNextStatuses getter', () {
      test('REQUESTED has CONFIRMED and CANCELLED as valid next statuses', () {
        final valid = BookingStatus.requested.validNextStatuses;
        expect(valid, contains(BookingStatus.confirmed));
        expect(valid, contains(BookingStatus.cancelled));
        expect(valid.length, 2);
      });

      test('CONFIRMED has COMPLETED and CANCELLED as valid next statuses', () {
        final valid = BookingStatus.confirmed.validNextStatuses;
        expect(valid, contains(BookingStatus.completed));
        expect(valid, contains(BookingStatus.cancelled));
        expect(valid.length, 2);
      });

      test('COMPLETED has no valid next statuses', () {
        expect(BookingStatus.completed.validNextStatuses, isEmpty);
      });

      test('CANCELLED has no valid next statuses', () {
        expect(BookingStatus.cancelled.validNextStatuses, isEmpty);
      });
    });
  });
}
