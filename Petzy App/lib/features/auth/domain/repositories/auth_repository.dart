import '../entities/user_entity.dart';

enum SocialProvider { google, apple }

class AuthProfile {
  const AuthProfile({
    required this.user,
    this.provider,
    this.firstName,
    this.lastName,
    this.phone,
  });

  final UserEntity user;
  final String? provider;
  final String? firstName;
  final String? lastName;
  final String? phone;
}

class AuthRegistrationResult {
  const AuthRegistrationResult({
    this.profile,
    required this.hasSession,
  });

  final AuthProfile? profile;
  final bool hasSession;
}

abstract class AuthRepository {
  AuthProfile? get currentProfile;
  Stream<AuthProfile?> get authStateChanges;

  Future<AuthProfile?> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthRegistrationResult> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  });

  Future<void> signInWithSocial(SocialProvider provider);
  Future<void> resetPassword(String email);

  Future<AuthProfile?> completeOAuthProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  });

  Future<void> completeFirstLogin();
  Future<void> signOut();
}
