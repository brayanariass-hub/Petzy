enum UserRole { admin, owner, sitter }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool isFirstLogin;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isFirstLogin,
  });

  UserEntity copyWith({
    String? name,
    bool? isFirstLogin,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
