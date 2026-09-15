import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/supabase_booking_datasource.dart';
import '../models/booking_model.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource dataSource;

  BookingRepositoryImpl(this.dataSource);

  @override
  Future<List<BookingEntity>> getBookings() async {
    return await dataSource.fetchBookings();
  }

  @override
  Future<BookingEntity> createBooking(BookingEntity booking) async {
    final model = BookingModel(
      id: booking.id,
      petId: booking.petId,
      sitterId: booking.sitterId,
      sitterServiceId: booking.sitterServiceId,
      startAt: booking.startAt,
      endAt: booking.endAt,
      status: booking.status,
      total: booking.total,
    );
    return await dataSource.createBooking(model);
  }
}