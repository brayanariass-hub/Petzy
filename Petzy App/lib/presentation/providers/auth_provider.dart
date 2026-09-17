import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

/// Convierte un usuario de Supabase a nuestra entidad de dominio UserEntity.
UserEntity _mapSupabaseUser(User user) {
  final meta = user.userMetadata ?? {};

  // Datos personales.
  final firstName = (meta['first_name'] as String?)?.trim();
  final lastName = (meta['last_name'] as String?)?.trim();
  final fullName = (meta['full_name'] as String?)?.trim();
  final name = [firstName, lastName]
      .whereType<String>()
      .where((part) => part.isNotEmpty)
      .join(' ');

  // Rol del usuario.
  // Supabase utiliza:
  // owner
  // sitter
  // admin
  // Si por alguna razón no existe el rol, usamos owner como
  // comportamiento por defecto para mantener compatibilidad
  // con usuarios antiguos.
  final roleStr = meta['role'] as String?;

  final role = switch (roleStr) {
    'sitter' => UserRole.sitter,
    'admin' => UserRole.admin,
    _ => UserRole.owner,
  };

  // Primer inicio de sesión.
  // Los usuarios nuevos reciben explícitamente:
  // is_first_login = true
  // Si un usuario antiguo no tiene este metadata, lo consideramos
  // como usuario ya existente y NO lo enviamos al onboarding.
  final firstLoginValue = meta['is_first_login'];

  final isFirstLogin = firstLoginValue is bool
      ? firstLoginValue
      : firstLoginValue?.toString().toLowerCase() == 'true';

  return UserEntity(
    id: user.id,
    name: name.isNotEmpty
        ? name
        : (fullName != null && fullName.isNotEmpty)
            ? fullName
            : (user.email?.split('@').first ?? 'Usuario'),
    email: user.email ?? '',
    role: role,

    // Por ahora este valor indica que el usuario tiene un rol válido
    // dentro de Petzy. Más adelante podemos convertirlo en una
    // validación real de perfil completo.
    profileComplete: roleStr == 'owner' ||
        roleStr == 'sitter' ||
        roleStr == 'admin',

    isFirstLogin: isFirstLogin,
  );
}

/// Proveedor del estado del usuario autenticado actual.
/// Se sincroniza con los eventos de autenticación de Supabase.
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, UserEntity?>((ref) {
  return AuthStateNotifier();
});

/// Mantiene sincronizado el usuario actual con Supabase Auth.
class AuthStateNotifier extends StateNotifier<UserEntity?> {
  StreamSubscription<AuthState>? _authSubscription;

  AuthStateNotifier() : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final client = Supabase.instance.client;

      if (!mounted) return;

      // Recuperar sesión existente al iniciar la aplicación.
      final currentUser = client.auth.currentUser;

      if (currentUser != null) {
        state = _mapSupabaseUser(currentUser);
      }

      // Escuchar cambios de autenticación.
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
      // No interrumpimos la aplicación si falla la recuperación
      // inicial de la sesión.
    }
  }

  /// Permite establecer manualmente el usuario.
  /// Útil para login, registro y pruebas.
  void setUser(UserEntity? user) {
    state = user;
  }

  /// Marca el onboarding de primer inicio como completado.
  ///
  /// Esto NO modifica ninguna tabla de la base de datos.
  /// Solamente actualiza el metadata del usuario en Supabase Auth.
  ///
  /// El flujo esperado es:
  ///
  /// Owner:
  /// primer login → registrar mascota → completeFirstLogin()
  ///
  /// Sitter:
  /// primer login → registrar servicios → completeFirstLogin()
  Future<void> completeFirstLogin() async {
    final currentUser = state;

    if (currentUser == null || !currentUser.isFirstLogin) {
      return;
    }

    await Supabase.instance.client.auth.updateUser(
      UserAttributes(
        data: {
          'is_first_login': false,
        },
      ),
    );

    if (mounted) {
      state = currentUser.copyWith(
        isFirstLogin: false,
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

/// Estado de las operaciones de autenticación.
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
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Controlador para Login, Registro, recuperación de contraseña,
/// perfil OAuth y Logout.
class AuthController extends StateNotifier<AuthControllerState> {
  final Ref _ref;

  AuthController(this._ref) : super(const AuthControllerState());

  /// Inicia sesión con correo y contraseña.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedEmail = email.trim();

    final emailRegExp =
        RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');

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
        errorMessage:
            'La contraseña debe tener al menos 6 caracteres.',
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
        _ref
            .read(authStateProvider.notifier)
            .setUser(_mapSupabaseUser(user));
      }

      state = state.copyWith(
        isLoading: false,
      );

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

  /// Registra una nueva cuenta con correo, contraseña,
  /// nombre, teléfono y rol.
  /// El trigger handle_new_user() de Supabase utiliza estos
  /// mismos metadata para crear profiles y owners/sitters.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final client = Supabase.instance.client;

      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'phone': phone.trim(),
          // Importante:
          // role.name devuelve:
          // owner / sitter / admin
          'role': role.name,

          // Todos los usuarios nuevos comienzan el onboarding.
          'is_first_login': true,
        },
      );

      final user = response.user;
      final session = response.session;

      if (session != null && user != null) {
        // Sesión iniciada automáticamente.
        // Esto ocurre cuando Confirm email está desactivado.
        _ref
            .read(authStateProvider.notifier)
            .setUser(_mapSupabaseUser(user));

        state = state.copyWith(
          isLoading: false,
          successMessage: '¡Cuenta creada con éxito!',
        );
      } else {
        // Requiere confirmación por correo.
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

  /// Envía un correo para restablecer la contraseña.
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    final normalizedEmail = email.trim();

    final emailRegExp =
        RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegExp.hasMatch(normalizedEmail)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ingresa un correo electrónico válido.',
      );

      return false;
    }

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        normalizedEmail,
      );

      state = state.copyWith(
        isLoading: false,
      );

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

  /// Completa el perfil de un usuario autenticado mediante OAuth.
  Future<bool> completeOAuthProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    try {
      final client = Supabase.instance.client;

      final response = await client.auth.updateUser(
        UserAttributes(
          data: {
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'full_name':
                '${firstName.trim()} ${lastName.trim()}'.trim(),
            'phone': phone.trim(),
            'role': role.name,

            // Después de completar el perfil OAuth,
            // debe iniciar el onboarding correspondiente.
            'is_first_login': true,
          },
        ),
      );

      final user = response.user;

      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No se pudo guardar el perfil en Supabase.',
        );

        return false;
      }

      _ref
          .read(authStateProvider.notifier)
          .setUser(_mapSupabaseUser(user));

      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Perfil completado!',
      );

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

  /// Cierra la sesión activa en Supabase.
  Future<void> signOut() async {
    try {
      final client = Supabase.instance.client;

      await client.auth.signOut();
    } catch (_) {
      // Incluso si Supabase devuelve un error,
      // limpiamos el estado local.
    }

    _ref
        .read(authStateProvider.notifier)
        .setUser(null);
  }

  /// Traduce errores comunes de Supabase Auth
  /// a mensajes entendibles para el usuario.
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

    if (lower.contains('signup') &&
        lower.contains('disabled')) {
      return 'El registro está deshabilitado temporalmente en Supabase.';
    }

    if (lower.contains('network') ||
        lower.contains('failed to fetch')) {
      return 'Error de conexión de red. Verifica tu internet.';
    }

    if (lower.contains('isinitialized') ||
        lower.contains('initialize the supabase')) {
      return 'Reiniciando conexión con Supabase... Por favor vuelve a presionar el botón.';
    }

    return message;
  }
}

/// Provider del controlador de autenticación.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref);
});