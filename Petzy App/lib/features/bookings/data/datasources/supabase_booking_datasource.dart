import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/create_booking_command.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> fetchOwnerBookings({
    int limit = 20,
    int offset = 0,
  });

  Future<BookingModel> createBooking(CreateBookingCommand command);
}

class SupabaseBookingDataSource implements BookingRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<BookingModel>> fetchOwnerBookings({
    int limit = 20,
    int offset = 0,
  }) async {
    if (limit <= 0) {
      throw const PostgrestException(
        message: 'El límite de reservas debe ser mayor que cero.',
      );
    }

    if (offset < 0) {
      throw const PostgrestException(
        message: 'El offset de reservas no puede ser negativo.',
      );
    }

    final rows = await _client
        .from('bookings')
        .select(
          'id, owner_id, pet_id, sitter_id, sitter_service_id, start_at, '
          'end_at, duration_minutes, buffer_minutes, location_type, '
          'service_address, owner_notes, sitter_notes, subtotal, '
          'platform_fee, sitter_earnings, status, total, currency, '
          'cancellation_reason, cancelled_at, pricing_snapshot, '
          'price_calculated_at, pricing_version, created_at, updated_at, '
          'owners!inner(profile_id)',
        )
        .eq('owners.profile_id', _client.auth.currentUser?.id ?? '')
        .order('start_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (rows as List)
        .map(
          (row) => BookingModel.fromSupabaseJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  @override
  Future<BookingModel> createBooking(
    CreateBookingCommand command,
  ) async {
    final endAt = command.startAt.add(
      Duration(minutes: command.durationMinutes),
    );

    final response = await _client.rpc(
      'create_booking',
      params: {
        'p_sitter_service_id': command.sitterServiceId,
        'p_pet_id': command.petId,
        'p_start_at': command.startAt.toUtc().toIso8601String(),
        'p_end_at': endAt.toUtc().toIso8601String(),
        'p_location_type': command.locationType,
        'p_service_address': command.serviceAddress,
        'p_service_location': null,
        'p_owner_notes': command.ownerNotes,
        'p_pet_count': command.petCount,
      },
    );

    if (response is! Map) {
      throw const PostgrestException(
        message: 'Respuesta inválida al crear la reserva.',
      );
    }

    return BookingModel.fromSupabaseJson(
      Map<String, dynamic>.from(response),
    );
  }
}