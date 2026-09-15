enum BookingStatus { pending, accepted, rejected, completed }

class BookingEntity {
  final String id;
  final String petId;
  final String sitterId;
  final String sitterServiceId;
  final DateTime startAt;
  final DateTime endAt;
  final BookingStatus status;
  final double total;

  const BookingEntity({
    required this.id,
    required this.petId,
    required this.sitterId,
    required this.sitterServiceId,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.total,
  });
}