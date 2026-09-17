class OwnerEntity {
  final String id;
  final String profileId;
  final String? preferredContactMethod;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  const OwnerEntity({
    required this.id,
    required this.profileId,
    this.preferredContactMethod,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });
}
