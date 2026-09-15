import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  BookingModel({
    required super.id,
    required super.petId,
    required super.sitterId,
    required super.sitterServiceId,
    required super.startAt,
    required super.endAt,
    required super.status,
    required super.total,
  });

  factory BookingModel.fromSupabaseJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      sitterId: json['sitter_id'] as String,
      sitterServiceId: json['sitter_service_id'] as String,
      startAt: DateTime.parse(json['start_at'] as String),
      endAt: DateTime.parse(json['end_at'] as String),
      status: _statusFromSupabase(json['status'] as String),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toSupabaseJson({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'sitter_id': sitterId,
      'pet_id': petId,
      'sitter_service_id': sitterServiceId,
      'start_at': startAt.toUtc().toIso8601String(),
      'end_at': endAt.toUtc().toIso8601String(),
      'duration_minutes': endAt.difference(startAt).inMinutes,
      'subtotal': total,
      'total': total,
      'currency': 'COP',
    };
  }

  static BookingStatus _statusFromSupabase(String status) {
    switch (status) {
      case 'accepted':
      case 'confirmed':
        return BookingStatus.accepted;
      case 'rejected':
        return BookingStatus.rejected;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }
}
