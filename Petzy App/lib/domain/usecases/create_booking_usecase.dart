import '../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  Future<BookingEntity> execute(BookingEntity booking) async {
    if (booking.totalAmount <= 0) {
      throw const ValidationFailure('El monto total debe ser mayor a 0');
    }
    return await repository.createBooking(booking);
  }
}