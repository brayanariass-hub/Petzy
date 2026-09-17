class ServiceEntity {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final bool active;

  const ServiceEntity({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.active,
  });
}
