enum UserRole { owner, caregiver }

class UserEntity {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const UserEntity({required this.id, required this.name, required this.email, required this.role});
}