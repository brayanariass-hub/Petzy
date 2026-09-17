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
      ownerId: booking.ownerId,
      petId: booking.petId,
      sitterId: booking.sitterId,
      sitterServiceId: booking.sitterServiceId,
      startAt: booking.startAt,
      endAt: booking.endAt,
      durationMinutes: booking.durationMinutes,
      bufferMinutes: booking.bufferMinutes,
      locationType: booking.locationType,
      serviceAddress: booking.serviceAddress,
      notes: booking.notes,
      subtotal: booking.subtotal,
      platformFee: booking.platformFee,
      sitterEarnings: booking.sitterEarnings,
      status: booking.status,
      total: booking.total,
      currency: booking.currency,
      cancellationReason: booking.cancellationReason,
      cancelledAt: booking.cancelledAt,
      pricingSnapshot: booking.pricingSnapshot,
      priceCalculatedAt: booking.priceCalculatedAt,
      pricingVersion: booking.pricingVersion,
      createdAt: booking.createdAt,
      updatedAt: booking.updatedAt,
    );
    return await dataSource.createBooking(model);
  }
}
