import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.ownerId,
    required super.sitterId,
    required super.petId,
    required super.sitterServiceId,
    required super.startAt,
    required super.endAt,
    required super.durationMinutes,
    required super.bufferMinutes,
    super.locationType,
    super.serviceAddress,
    super.ownerNotes,
    super.sitterNotes,
    required super.subtotal,
    required super.platformFee,
    required super.sitterEarnings,
    required super.total,
    required super.currency,
    required super.status,
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
      id: _requiredString(json, 'id'),
      ownerId: _requiredString(json, 'owner_id'),
      sitterId: _requiredString(json, 'sitter_id'),
      petId: _requiredString(json, 'pet_id'),
      sitterServiceId: _requiredString(json, 'sitter_service_id'),
      startAt: _requiredDateTime(json, 'start_at'),
      endAt: _requiredDateTime(json, 'end_at'),
      durationMinutes: _requiredInt(json, 'duration_minutes'),
      bufferMinutes: _requiredInt(json, 'buffer_minutes'),
      locationType: json['location_type'] as String?,
      serviceAddress: json['service_address'] as String?,
      ownerNotes: json['owner_notes'] as String?,
      sitterNotes: json['sitter_notes'] as String?,
      subtotal: _requiredDouble(json, 'subtotal'),
      platformFee: _requiredDouble(json, 'platform_fee'),
      sitterEarnings: _requiredDouble(json, 'sitter_earnings'),
      total: _requiredDouble(json, 'total'),
      currency: _requiredString(json, 'currency'),
      status: _statusFromSupabase(_requiredString(json, 'status')),
      cancellationReason: json['cancellation_reason'] as String?,
      cancelledAt: _nullableDateTime(json['cancelled_at']),
      pricingSnapshot: json['pricing_snapshot'] == null
          ? null
          : Map<String, dynamic>.from(json['pricing_snapshot'] as Map),
      priceCalculatedAt: _nullableDateTime(json['price_calculated_at']),
      pricingVersion: _requiredInt(json, 'pricing_version'),
      createdAt: _requiredDateTime(json, 'created_at'),
      updatedAt: _requiredDateTime(json, 'updated_at'),
    );
  }

  static BookingStatus _statusFromSupabase(String value) {
    return switch (value) {
      'requested' => BookingStatus.requested,
      'accepted' => BookingStatus.accepted,
      'confirmed' => BookingStatus.confirmed,
      'in_progress' => BookingStatus.inProgress,
      'completed' => BookingStatus.completed,
      'cancelled' => BookingStatus.cancelled,
      'rejected' => BookingStatus.rejected,
      'disputed' => BookingStatus.disputed,
      _ => throw FormatException('Unknown booking status: $value'),
    };
  }

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid booking field: $key');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toInt();
    throw FormatException('Missing or invalid booking field: $key');
  }

  static double _requiredDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) return value.toDouble();
    throw FormatException('Missing or invalid booking field: $key');
  }

  static DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) return DateTime.parse(value);
    throw FormatException('Missing or invalid booking field: $key');
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    throw const FormatException('Invalid nullable datetime value.');
  }
}
