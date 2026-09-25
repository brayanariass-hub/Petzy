import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/create_booking_command.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/supabase_booking_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource dataSource;

  BookingRepositoryImpl(this.dataSource);

  @override
  Future<List<BookingEntity>> fetchOwnerBookings(
      {int limit = 20, int offset = 0}) async {
    return await dataSource.fetchOwnerBookings(limit: limit, offset: offset);
  }

  @override
  Future<BookingEntity> createBooking(CreateBookingCommand command) async {
    return await dataSource.createBooking(command);
  }
}
