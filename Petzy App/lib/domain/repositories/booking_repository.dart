import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<List<BookingEntity>> getBookings();
  Future<BookingEntity> createBooking(BookingEntity booking);
}