import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

/// Convierte un User de Supabase a nuestra entidad de dominio [UserEntity]
UserEntity _mapSupabaseUser(User user) {
  final meta = user.userMetadata ?? {};
  final firstName = (meta['first_name'] as String?)?.trim();
  final lastName = (meta['last_name'] as String?)?.trim();
  final fullName = (meta['full_name'] as String?)?.trim();
  final name = [firstName, lastName]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(' ');
  final roleStr = meta['role'] as String?;
  final role = roleStr == 'sitter' ? UserRole.sitter : UserRole.owner;

  return UserEntity(
    id: user.id,
    name: name.isNotEmpty
        ? name
        : (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user.email?.split('@').first ?? 'Usuario'),
    email: user.email ?? '',
    role: role,
    profileComplete: roleStr == 'owner' || roleStr == 'sitter',
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
      final client = Supabase.instance.client;
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

  /// Permite establecer manualmente el usuario (p.ej. para pruebas)
  void setUser(UserEntity? user) {
    state = user;
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
      final client = Supabase.instance.client;
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
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final client = Supabase.instance.client;
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
          'role': role.name,
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
      await Supabase.instance.client.auth
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

  Future<bool> completeOAuthProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);

    try {
      final client = Supabase.instance.client;
      final response = await client.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'full_name': '${firstName.trim()} ${lastName.trim()}'.trim(),
            'phone': phone.trim(),
            'role': role.name,
          },
        ),
      );
      final user = response.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No se pudo guardar el perfil en Supabase.',
        );
        return false;
      }

      _ref.read(authStateProvider.notifier).setUser(_mapSupabaseUser(user));
      state = state.copyWith(
          isLoading: false, successMessage: '¡Perfil completado!');
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
      final client = Supabase.instance.client;
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
