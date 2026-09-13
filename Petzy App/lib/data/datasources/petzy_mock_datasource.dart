abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> fetchBookings();
  Future<BookingModel> createBooking(BookingModel booking);
}

class PetzyMockDataSource implements BookingRemoteDataSource {
  final List<BookingModel> _mockBookings = [
    BookingModel(
      id: 'b1',
      petId: 'p1',
      caregiverId: 'c1',
      date: DateTime.now().add(const Duration(days: 1)),
      status: BookingStatus.pending,
      totalAmount: 25.0,
    ),
  ];

  @override
  Future<List<BookingModel>> fetchBookings() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockBookings;
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockBookings.add(booking);
    return booking;
  }
}