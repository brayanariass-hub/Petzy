class PetDraft {
  const PetDraft({
    required this.name,
    required this.species,
    this.breed,
    this.sex,
    this.birthDate,
    this.weightKg,
    this.size,
    this.description,
    this.behavioralNotes,
    this.medicalNotes,
    this.allergies,
    this.medications,
    this.emergencyInstructions,
    this.imagePath,
  });

  final String name;
  final String species;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final double? weightKg;
  final String? size;
  final String? description;
  final String? behavioralNotes;
  final String? medicalNotes;
  final String? allergies;
  final String? medications;
  final String? emergencyInstructions;
  final String? imagePath;

  factory PetDraft.fromMap(
    Map<String, dynamic> data, {
    String? imagePath,
  }) {
    return PetDraft(
      name: data['name'] as String,
      species: data['species'] as String,
      breed: data['breed'] as String?,
      sex: data['sex'] as String?,
      birthDate: data['birth_date'] == null
          ? null
          : DateTime.parse(data['birth_date'] as String),
      weightKg: (data['weight_kg'] as num?)?.toDouble(),
      size: data['size'] as String?,
      description: data['description'] as String?,
      behavioralNotes: data['behavioral_notes'] as String?,
      medicalNotes: data['medical_notes'] as String?,
      allergies: data['allergies'] as String?,
      medications: data['medications'] as String?,
      emergencyInstructions: data['emergency_instructions'] as String?,
      imagePath: imagePath,
    );
  }
}
