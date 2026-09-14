import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  BookingModel({
    required String id,
    required String petId,
    required String caregiverId,
    required DateTime date,
    required BookingStatus status,
    required double totalAmount,
  }) : super(
          id: id,
          petId: petId,
          caregiverId: caregiverId,
          date: date,
          status: status,
          totalAmount: totalAmount,
        );

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'],
      petId: json['petId'],
      caregiverId: json['caregiverId'],
      date: DateTime.parse(json['date']),
      status: BookingStatus.values.byName(json['status']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'petId': petId,
      'caregiverId': caregiverId,
      'date': date.toIso8601String(),
      'status': status.name,
      'totalAmount': totalAmount,
    };
  }
}
