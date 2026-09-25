import '../entities/booking_entity.dart';
import '../entities/create_booking_command.dart';

abstract class BookingRepository {
  Future<List<BookingEntity>> fetchOwnerBookings({
    int limit = 20,
    int offset = 0,
  });
  Future<BookingEntity> createBooking(CreateBookingCommand command);
}
