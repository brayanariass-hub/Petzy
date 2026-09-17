import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  BookingModel({
    required super.id,
    required super.ownerId,
    required super.petId,
    required super.sitterId,
    required super.sitterServiceId,
    required super.startAt,
    required super.endAt,
    required super.durationMinutes,
    required super.bufferMinutes,
    super.locationType,
    super.serviceAddress,
    super.notes,
    required super.subtotal,
    required super.platformFee,
    required super.sitterEarnings,
    required super.status,
    required super.total,
    required super.currency,
    super.cancellationReason,
    super.cancelledAt,
    super.pricingSnapshot,
    super.priceCalculatedAt,
    required super.pricingVersion,
    required super.createdAt,
    required super.updatedAt,
  });

  factory BookingModel.fromSupabaseJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      petId: json['pet_id'] as String,
      sitterId: json['sitter_id'] as String,
      sitterServiceId: json['sitter_service_id'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      durationMinutes: json['duration_minutes'] as int,
      bufferMinutes: (json['buffer_minutes'] as int?) ?? 0,
      locationType: json['location_type'] as String?,
      serviceAddress: json['service_address'] as String?,
      notes: json['notes'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      sitterEarnings: (json['sitter_earnings'] as num?)?.toDouble() ?? 0,
      status: _statusFromSupabase(json['status'] as String),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'COP',
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: _dateTimeFromJson(json['cancelled_at']),
      pricingSnapshot: json['pricing_snapshot'] == null
          ? null
          : Map<String, dynamic>.from(json['pricing_snapshot'] as Map),
      priceCalculatedAt: _dateTimeFromJson(json['price_calculated_at']),
      pricingVersion: (json['pricing_version'] as int?) ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'owner_id': ownerId,
      'sitter_id': sitterId,
      'pet_id': petId,
      'sitter_service_id': sitterServiceId,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'duration_minutes': durationMinutes,
      'buffer_minutes': bufferMinutes,
      'location_type': locationType,
      'service_address': serviceAddress,
      'notes': notes,
      'subtotal': subtotal,
      'platform_fee': platformFee,
      'sitter_earnings': sitterEarnings,
      'total': total,
      'currency': currency,
      'pricing_snapshot': pricingSnapshot,
      'price_calculated_at': priceCalculatedAt?.toUtc().toIso8601String(),
      'pricing_version': pricingVersion,
    };
  }

  static BookingStatus _statusFromSupabase(String status) {
    switch (status) {
      case 'requested':
        return BookingStatus.requested;
      case 'accepted':
        return BookingStatus.accepted;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.requested;
    }
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    return value == null ? null : DateTime.parse(value as String);
  }
}
