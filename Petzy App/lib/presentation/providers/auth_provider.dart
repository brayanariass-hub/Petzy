import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import '../../domain/entities/user_entity.dart';

/// Obtiene el cliente de Supabase garantizando que la instancia esté inicializada.
/// Si la app solo fue recargada (Hot Reload) sin ejecutar main(), la inicializa dinámicamente.
Future<SupabaseClient> _getSupabaseClient() async {
  try {
    return Supabase.instance.client;
  } catch (_) {
    await Supabase.initialize(
      url: SupabaseConstants.supabaseUrl,
      publishableKey: SupabaseConstants.supabasePublishableKey,
    );
    return Supabase.instance.client;
  }
}

/// Convierte un User de Supabase a nuestra entidad de dominio [UserEntity]
UserEntity _mapSupabaseUser(User user) {
  final meta = user.userMetadata ?? {};
  final name = (meta['full_name'] as String?)?.trim();
  final roleStr = meta['role'] as String?;
  // Acepta el valor anterior para no desconectar a sitters ya registrados.
  final role = switch (roleStr) {
    'admin' => UserRole.admin,
    'sitter' || 'caregiver' => UserRole.sitter,
    _ => UserRole.owner,
  };

  // Se lee el flag de metadata. Si no existe, por defecto es true solo si es owner
  final isFirstLogin =
      (meta['is_first_login'] as bool?) ?? (role == UserRole.owner);

  return UserEntity(
    id: user.id,
    name: (name != null && name.isNotEmpty)
        ? name
        : (user.email?.split('@').first ?? 'Usuario'),
    email: user.email ?? '',
    role: role,
    isFirstLogin: isFirstLogin,
  );
}

/// Proveedor del estado del usuario autenticado actual.
/// Se sincroniza en tiempo real con los eventos de sesión de Supabase.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, UserEntity?>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<UserEntity?> {
  StreamSubscription<AuthState>? _authSubscription;

  AuthStateNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final client = await _getSupabaseClient();
      if (!mounted) return;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        state = _mapSupabaseUser(currentUser);
      }

      _authSubscription = client.auth.onAuthStateChange.listen((data) {
        if (!mounted) return;
        final sessionUser = data.session?.user;
        if (sessionUser != null) {
          state = _mapSupabaseUser(sessionUser);
        } else {
          state = null;
        }
      });
    } catch (_) {
      // Manejo seguro si falla la inicialización inicial
    }
  }

  /// Permite establecer manualmente el usuario (p.ej. para pruebas o completar onboarding)
  void setUser(UserEntity? user) {
    state = user;
  }

  /// Marca de forma persistente que el usuario completó su onboarding inicial de mascota
  Future<void> completeFirstLogin() async {
    if (state == null) return;
    final updatedUser = state!.copyWith(isFirstLogin: false);
    state = updatedUser;

    try {
      final client = await _getSupabaseClient();
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'is_first_login': false,
          },
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Estado de la operación de autenticación (idle, loading, error, success)
class AuthControllerState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthControllerState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthControllerState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthControllerState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controlador para operaciones reales de Login, Registro y Logout con Supabase
class AuthController extends StateNotifier<AuthControllerState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthControllerState());

  /// Inicia sesión con correo y contraseña en Supabase
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    final normalizedEmail = email.trim();
    final emailRegExp = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(normalizedEmail)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ingresa un correo electrónico válido.',
      );
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'La contraseña debe tener al menos 6 caracteres.',
      );
      return false;
    }

    try {
      final client = await _getSupabaseClient();
      final response = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _ref.read(authStateProvider.notifier).setUser(_mapSupabaseUser(user));
      }

      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.toString()),
      );
      return false;
    }
  }

  /// Registra una nueva cuenta con correo, contraseña, nombre y rol en Supabase
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final client = await _getSupabaseClient();
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': name.trim(),
          'role': role.name,
          'is_first_login':
              role == UserRole.owner, // Solo los dueños deben hacer onboarding
        },
      );

      final user = response.user;
      final session = response.session;

      if (session != null && user != null) {
        // Sesión iniciada automáticamente (Confirm email desactivado)
        _ref.read(authStateProvider.notifier).setUser(_mapSupabaseUser(user));
        state = state.copyWith(
          isLoading: false,
          successMessage: '¡Cuenta creada con éxito!',
        );
      } else {
        // Requiere confirmación por correo (Confirm email activado)
        state = state.copyWith(
          isLoading: false,
          successMessage:
              'Registro exitoso. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.',
        );
      }
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _translateAuthError(e.toString()),
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    final normalizedEmail = email.trim();
    final emailRegExp = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(normalizedEmail)) {
      state = state.copyWith(
          isLoading: false,
          errorMessage: 'Ingresa un correo electrónico válido.');
      return false;
    }

    try {
      await (await _getSupabaseClient())
          .auth
          .resetPasswordForEmail(normalizedEmail);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: _translateAuthError(e.message));
      return false;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: _translateAuthError(e.toString()));
      return false;
    }
  }

  /// Cierra la sesión activa en Supabase y limpia el estado local
  Future<void> signOut() async {
    try {
      final client = await _getSupabaseClient();
      await client.auth.signOut();
    } catch (_) {}
    _ref.read(authStateProvider.notifier).setUser(null);
  }

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('email already in use')) {
      return 'Ya existe una cuenta con este correo electrónico.';
    }
    if (lower.contains('password should be at least')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de ingresar.';
    }
    if (lower.contains('signup') && lower.contains('disabled')) {
      return 'El registro está deshabilitado temporalmente en Supabase.';
    }
    if (lower.contains('network') || lower.contains('failed to fetch')) {
      return 'Error de conexión de red. Verifica tu internet.';
    }
    if (lower.contains('isinitialized') ||
        lower.contains('initialize the supabase')) {
      return 'Reiniciando conexión con Supabase... Por favor vuelve a presionar el botón.';
    }
    return message;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref);
});
