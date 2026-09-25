import '../../../../core/errors/failures.dart';
import '../entities/booking_entity.dart';
import '../entities/create_booking_command.dart';
import '../repositories/booking_repository.dart';

class CreateBookingUseCase {
  const CreateBookingUseCase(this.repository);

  final BookingRepository repository;

  Future<BookingEntity> execute(
    CreateBookingCommand command,
  ) async {
    if (command.petId.trim().isEmpty) {
      throw const ValidationFailure(
        'Debes seleccionar una mascota.',
      );
    }

    if (command.sitterServiceId.trim().isEmpty) {
      throw const ValidationFailure(
        'Debes seleccionar un servicio.',
      );
    }

    if (command.durationMinutes <= 0) {
      throw const ValidationFailure(
        'La duración de la reserva no es válida.',
      );
    }

    if (command.petCount < 1 || command.petCount > 20) {
      throw const ValidationFailure(
        'La cantidad de mascotas no es válida.',
      );
    }

    if (command.locationType.trim().isEmpty) {
      throw const ValidationFailure(
        'Debes seleccionar el tipo de ubicación.',
      );
    }

    return repository.createBooking(command);
  }
}