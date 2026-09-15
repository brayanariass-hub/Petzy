import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/petzy_mock_datasource.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/create_booking_usecase.dart';

final dataSourceProvider = Provider<BookingRemoteDataSource>((ref) => PetzyMockDataSource());

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => BookingRepositoryImpl(ref.watch(dataSourceProvider)),
);

final createBookingUseCaseProvider = Provider<CreateBookingUseCase>(
  (ref) => CreateBookingUseCase(ref.watch(bookingRepositoryProvider)),
);

class BookingNotifier extends StateNotifier<AsyncValue<List<BookingEntity>>> {
  final BookingRepository _repository;
  final CreateBookingUseCase _createBookingUseCase;

  BookingNotifier(this._repository, this._createBookingUseCase) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    try {
      final bookings = await _repository.getBookings();
      state = AsyncValue.data(bookings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBooking(BookingEntity booking) async {
    try {
      await _createBookingUseCase.execute(booking);
      await loadBookings();
    } catch (e) {
      rethrow;
    }
  }
}

final bookingNotifierProvider = StateNotifierProvider<BookingNotifier, AsyncValue<List<BookingEntity>>>(
  (ref) => BookingNotifier(
    ref.watch(bookingRepositoryProvider),
    ref.watch(createBookingUseCaseProvider),
  ),
);