import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<BookingModel>> fetchBookings();
  Future<BookingModel> createBooking(BookingModel booking);
}

class SupabaseBookingDataSource implements BookingRemoteDataSource {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<BookingModel>> fetchBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final rows = await _client
        .from('bookings')
        .select()
        .eq('owner_id', user.id)
        .order('start_at', ascending: false);

    return (rows as List)
        .map((row) => BookingModel.fromSupabaseJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<BookingModel> createBooking(BookingModel booking) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para crear una reserva.');
    }

    final row = await _client
        .from('bookings')
        .insert(booking.toSupabaseJson(ownerId: user.id))
        .select()
        .single();

    return BookingModel.fromSupabaseJson(Map<String, dynamic>.from(row));
  }
}
