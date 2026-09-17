import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../screens/booking_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_pet_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegisteringPet = state.matchedLocation == '/register-pet';

      // 1. Si no hay usuario autenticado, forzar navegación a /login
      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      // 2. Condición: SOLO si es dueño Y es su primera vez debe ir a registrar mascota
      final isOwnerFirstTime = user.role == UserRole.owner && user.isFirstLogin;

      if (isOwnerFirstTime) {
        // Si aún no está en la pantalla de registro, mandarlo para allá
        return isRegisteringPet ? null : '/register-pet';
      }

      // 3. Para sitters o dueños que ya registraron su mascota:
      // Si intentan entrar al login o al registro inicial de mascota, enviarlos al home
      if (isLoggingIn || isRegisteringPet) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register-pet',
        builder: (context, state) => const RegisterPetScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const BookingScreen(),
      ),
    ],
  );
});
