import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/bookings/data/datasources/supabase_booking_datasource.dart';
import '../../features/bookings/data/repositories/booking_repository_impl.dart';
import '../../features/bookings/domain/repositories/booking_repository.dart';
import '../../features/pets/data/repositories/pet_repository_impl.dart';
import '../../features/pets/domain/repositories/pet_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return SupabasePetRepository();
});

final bookingDataSourceProvider = Provider<BookingRemoteDataSource>((ref) {
  return SupabaseBookingDataSource();
});

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepositoryImpl(ref.watch(bookingDataSourceProvider));
});
