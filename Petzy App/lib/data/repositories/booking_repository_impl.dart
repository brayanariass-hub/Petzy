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
      caregiverId: booking.caregiverId,
      date: booking.date,
      status: booking.status,
      totalAmount: booking.totalAmount,
    );
    return await dataSource.createBooking(model);
  }
}