import 'package:flutter_test/flutter_test.dart';
import 'package:petzy/features/bookings/domain/entities/booking_entity.dart';

void main() {
  test('booking statuses only allow forward domain transitions', () {
    expect(
      BookingStatus.requested.canTransitionTo(BookingStatus.accepted),
      isTrue,
    );
    expect(
      BookingStatus.accepted.canTransitionTo(BookingStatus.confirmed),
      isTrue,
    );
    expect(
      BookingStatus.confirmed.canTransitionTo(BookingStatus.requested),
      isFalse,
    );
    expect(
      BookingStatus.completed.canTransitionTo(BookingStatus.cancelled),
      isFalse,
    );
  });
}
