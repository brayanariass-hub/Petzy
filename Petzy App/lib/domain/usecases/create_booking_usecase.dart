import '../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase(this.repository);

  Future<BookingEntity> execute(BookingEntity booking) async {
    if (booking.total <= 0) {
      throw const ValidationFailure('El monto total debe ser mayor a 0');
    }
    if (booking.endAt.isBefore(booking.startAt) || booking.endAt.isAtSameMomentAs(booking.startAt)) {
      throw const ValidationFailure('La hora de finalización debe ser posterior a la de inicio');
    }
    return await repository.createBooking(booking);
  }
}