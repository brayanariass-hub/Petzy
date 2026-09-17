enum UserRole { owner, sitter, admin }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool profileComplete;
  final bool isFirstLogin;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileComplete = true,
    this.isFirstLogin = true,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    bool? profileComplete,
    bool? isFirstLogin,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileComplete: profileComplete ?? this.profileComplete,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
