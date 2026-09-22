import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../screens/booking_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/register_pet_screen.dart';
import '../screens/sitter_services_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final registering = state.matchedLocation == '/register';
      final registeringPet = state.matchedLocation == '/register-pet';
      final isReturnToPets =
          state.uri.queryParameters['returnToPets'] == 'true';
      final sitterServices = state.matchedLocation == '/sitter-services';
      if (user == null && !loggingIn && !registering) {
        return '/login';
      }
      if (user != null && !user.profileComplete && !registering) {
        return '/register';
      }
      if (user != null &&
          user.role == UserRole.admin &&
          (loggingIn || registering || (registeringPet && !isReturnToPets) || sitterServices)) {
        return '/home';
      }
      if (user != null && user.profileComplete && user.isFirstLogin) {
        if (user.role == UserRole.owner && !registeringPet) {
          return '/register-pet';
        }
        if (user.role == UserRole.sitter && !sitterServices) {
          return '/sitter-services';
        }
      }
      if (user != null &&
          user.profileComplete &&
          !user.isFirstLogin &&
          (loggingIn || registering || (registeringPet && !isReturnToPets) || sitterServices)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: '/register-pet',
          builder: (context, state) => RegisterPetScreen(
                returnToPets:
                    state.uri.queryParameters['returnToPets'] == 'true',
              )),
      GoRoute(
          path: '/sitter-services',
          builder: (context, state) => const SitterServicesScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/booking', builder: (context, state) => const BookingScreen()),
    ],
  );
});
