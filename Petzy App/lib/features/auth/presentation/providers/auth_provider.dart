import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final currentAuthProfileProvider = Provider<AuthProfile?>((ref) {
  return ref.watch(authRepositoryProvider).currentProfile;
});

final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, UserEntity?>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthStateNotifier extends StateNotifier<UserEntity?> {
  AuthStateNotifier(this._repository) : super(null) {
    _subscription = _repository.authStateChanges.listen((profile) {
      if (mounted) state = profile?.user;
    });
    final profile = _repository.currentProfile;
    if (profile != null) state = profile.user;
  }

  final AuthRepository _repository;
  StreamSubscription<AuthProfile?>? _subscription;

  void setUser(UserEntity? user) {
    state = user;
  }

  Future<void> completeFirstLogin() async {
    final currentUser = state;
    if (currentUser == null || !currentUser.isFirstLogin) return;

    await _repository.completeFirstLogin();
    if (mounted) state = currentUser.copyWith(isFirstLogin: false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

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

class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._repository, this._ref)
      : super(const AuthControllerState());

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> signInWithOAuth(SocialProvider provider) {
    return _repository.signInWithSocial(provider);
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (!_validEmail(normalizedEmail)) {
      _setError('Ingresa un correo electrónico válido.');
      return false;
    }
    if (password.length < 6) {
      _setError('La contraseña debe tener al menos 6 caracteres.');
      return false;
    }

    _start();
    try {
      final profile = await _repository.signInWithEmail(
        email: normalizedEmail,
        password: password,
      );
      if (profile == null) throw Exception('No se pudo iniciar sesión.');
      _ref.read(authStateProvider.notifier).setUser(profile.user);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      _setError(_translateError(error.toString()));
      return false;
    }
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    _start();
    try {
      final result = await _repository.signUpWithEmail(
        email: email.trim(),
        password: password,
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        role: role,
      );
      if (result.profile != null && result.hasSession) {
        _ref.read(authStateProvider.notifier).setUser(result.profile!.user);
      }
      state = state.copyWith(
        isLoading: false,
        successMessage: result.hasSession
            ? '¡Cuenta creada con éxito!'
            : 'Registro exitoso. Revisa tu correo para confirmar tu cuenta antes de iniciar sesión.',
      );
      return true;
    } catch (error) {
      _setError(_translateError(error.toString()));
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    if (!_validEmail(email.trim())) {
      _setError('Ingresa un correo electrónico válido.');
      return false;
    }
    _start();
    try {
      await _repository.resetPassword(email.trim());
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      _setError(_translateError(error.toString()));
      return false;
    }
  }

  Future<bool> completeOAuthProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    _start();
    try {
      final profile = await _repository.completeOAuthProfile(
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        phone: phone.trim(),
        role: role,
      );
      if (profile == null) throw Exception('No se pudo guardar el perfil.');
      _ref.read(authStateProvider.notifier).setUser(profile.user);
      state = state.copyWith(
        isLoading: false,
        successMessage: '¡Perfil completado!',
      );
      return true;
    } catch (error) {
      _setError(_translateError(error.toString()));
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } finally {
      _ref.read(authStateProvider.notifier).setUser(null);
    }
  }

  void _start() {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
  }

  void _setError(String message) {
    state = state.copyWith(isLoading: false, errorMessage: message);
  }

  bool _validEmail(String email) {
    return RegExp(r'^[\w.\-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _translateError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('email already in use')) {
      return 'Ya existe una cuenta con este correo electrónico.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electrónico antes de ingresar.';
    }
    if (lower.contains('network') || lower.contains('failed to fetch')) {
      return 'Error de conexión de red. Verifica tu internet.';
    }
    return message;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});
