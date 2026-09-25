import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/create_booking_command.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_booking_usecase.dart';

final createBookingUseCaseProvider = Provider<CreateBookingUseCase>(
  (ref) => CreateBookingUseCase(ref.watch(bookingRepositoryProvider)),
);

class BookingNotifier extends StateNotifier<AsyncValue<List<BookingEntity>>> {
  final BookingRepository _repository;
  final CreateBookingUseCase _createBookingUseCase;

  BookingNotifier(this._repository, this._createBookingUseCase)
      : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings({int limit = 20, int offset = 0}) async {
    state = const AsyncValue.loading();
    try {
      final bookings =
          await _repository.fetchOwnerBookings(limit: limit, offset: offset);
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBooking(CreateBookingCommand command) async {
    await _createBookingUseCase.execute(command);
    await loadBookings();
  }
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, AsyncValue<List<BookingEntity>>>(
  (ref) => BookingNotifier(
    ref.watch(bookingRepositoryProvider),
    ref.watch(createBookingUseCaseProvider),
  ),
);
