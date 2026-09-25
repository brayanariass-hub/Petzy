enum BookingStatus {
  requested,
  accepted,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rejected,
  disputed,
}

extension BookingStatusTransitions on BookingStatus {
  bool canTransitionTo(BookingStatus next) {
    if (this == next) return true;

    return switch (this) {
      BookingStatus.requested => next == BookingStatus.accepted ||
          next == BookingStatus.cancelled ||
          next == BookingStatus.rejected,
      BookingStatus.accepted =>
        next == BookingStatus.confirmed || next == BookingStatus.cancelled,
      BookingStatus.confirmed =>
        next == BookingStatus.inProgress || next == BookingStatus.cancelled,
      BookingStatus.inProgress => next == BookingStatus.completed,
      BookingStatus.completed => false,
      BookingStatus.cancelled => false,
      BookingStatus.rejected => false,
      BookingStatus.disputed => false,
    };
  }
}

class BookingEntity {
  final String id;

  final String ownerId;
  final String sitterId;
  final String petId;
  final String sitterServiceId;

  final DateTime startAt;
  final DateTime endAt;

  final int durationMinutes;
  final int bufferMinutes;

  final String? locationType;
  final String? serviceAddress;

  final String? ownerNotes;
  final String? sitterNotes;

  final double subtotal;
  final double platformFee;
  final double sitterEarnings;
  final double total;

  final String currency;

  final BookingStatus status;

  final String? cancellationReason;
  final DateTime? cancelledAt;

  final Map<String, dynamic>? pricingSnapshot;

  final DateTime? priceCalculatedAt;
  final int pricingVersion;

  final DateTime createdAt;
  final DateTime updatedAt;

  const BookingEntity({
    required this.id,
    required this.ownerId,
    required this.sitterId,
    required this.petId,
    required this.sitterServiceId,
    required this.startAt,
    required this.endAt,
    required this.durationMinutes,
    required this.bufferMinutes,
    this.locationType,
    this.serviceAddress,
    this.ownerNotes,
    this.sitterNotes,
    required this.subtotal,
    required this.platformFee,
    required this.sitterEarnings,
    required this.total,
    required this.currency,
    required this.status,
    this.cancellationReason,
    this.cancelledAt,
    this.pricingSnapshot,
    this.priceCalculatedAt,
    required this.pricingVersion,
    required this.createdAt,
    required this.updatedAt,
  });
}
