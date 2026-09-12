enum BookingStatus { pending, accepted, rejected, completed }

class BookingEntity {
  final String id;
  final String petId;
  final String caregiverId;
  final DateTime date;
  final BookingStatus status;
  final double totalAmount;

  const BookingEntity({
    required this.id,
    required this.petId,
    required this.caregiverId,
    required this.date,
    required this.status,
    required this.totalAmount,
  });
}