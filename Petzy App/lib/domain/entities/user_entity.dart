enum UserRole { owner, sitter }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final bool profileComplete;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileComplete = true,
  });
}
