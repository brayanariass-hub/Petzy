class PetEntity {
  final String id;
  final String ownerId;
  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final double? weightKg;
  final String? size;
  final String? photoUrl;
  final String? description;
  final String? behavioralNotes;
  final String? medicalNotes;
  final String? allergies;
  final String? medications;
  final String? emergencyInstructions;

  const PetEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.weightKg,
    this.size,
    this.photoUrl,
    this.description,
    this.behavioralNotes,
    this.medicalNotes,
    this.allergies,
    this.medications,
    this.emergencyInstructions,
  });
}
