import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  AuthProfile? get currentProfile {
    try {
      final user = _client.auth.currentUser;
      return user == null ? null : _mapUser(user);
    } on AssertionError {
      return null;
    }
  }

  @override
  Stream<AuthProfile?> get authStateChanges {
    try {
      return _client.auth.onAuthStateChange.asyncExpand((event) {
        final user = event.session?.user;
        return user == null
            ? Stream<AuthProfile?>.value(null)
            : Stream<AuthProfile?>.fromFuture(_mapUserSecure(user));
      });
    } on AssertionError {
      return const Stream<AuthProfile?>.empty();
    }
  }

  @override
  Future<AuthProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.user == null ? null : _mapUserSecure(response.user!);
  }

  @override
  Future<AuthRegistrationResult> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': role.name,
        'is_first_login': true,
      },
    );
    return AuthRegistrationResult(
      profile:
          response.user == null ? null : await _mapUserSecure(response.user!),
      hasSession: response.session != null,
    );
  }

  @override
  Future<void> signInWithSocial(SocialProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider == SocialProvider.google
          ? OAuthProvider.google
          : OAuthProvider.apple,
    );
  }

  @override
  Future<void> resetPassword(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<AuthProfile?> completeOAuthProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    final response = await _client.auth.updateUser(
      UserAttributes(
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName'.trim(),
          'phone': phone,
          'role': role.name,
          'is_first_login': true,
        },
      ),
    );
    return response.user == null ? null : _mapUserSecure(response.user!);
  }

  @override
  Future<void> completeFirstLogin() async {
    await _client.auth.updateUser(
      UserAttributes(data: {'is_first_login': false}),
    );
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  Future<AuthProfile> _mapUserSecure(User user) async {
    String? roleName;
    try {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      roleName = profile?['role']?.toString();
    } catch (_) {
      roleName = null;
    }
    return _mapUser(user, roleName: roleName);
  }

  AuthProfile _mapUser(User user, {String? roleName}) {
    final metadata = user.userMetadata ?? <String, dynamic>{};
    final firstName = (metadata['first_name'] as String?)?.trim();
    final lastName = (metadata['last_name'] as String?)?.trim();
    final fullName = (metadata['full_name'] as String?)?.trim();
    final name = [firstName, lastName]
        .whereType<String>()
        .where((part) => part.isNotEmpty)
        .join(' ');
    final firstLogin = metadata['is_first_login'];

    final profile = UserEntity(
      id: user.id,
      name: name.isNotEmpty
          ? name
          : (fullName?.isNotEmpty == true
              ? fullName!
              : (user.email?.split('@').first ?? 'Usuario')),
      email: user.email ?? '',
      role: switch (roleName) {
        'sitter' => UserRole.sitter,
        'admin' => UserRole.admin,
        _ => UserRole.owner,
      },
      profileComplete:
          roleName == 'owner' || roleName == 'sitter' || roleName == 'admin',
      isFirstLogin: firstLogin is bool
          ? firstLogin
          : firstLogin?.toString().toLowerCase() == 'true',
    );

    return AuthProfile(
      user: profile,
      provider: user.appMetadata['provider']?.toString(),
      firstName: firstName,
      lastName: lastName,
      phone: (metadata['phone'] as String?)?.trim(),
    );
  }
}
