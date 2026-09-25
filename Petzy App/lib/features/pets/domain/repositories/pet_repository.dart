import '../entities/pet_entity.dart';
import '../entities/pet_draft.dart';

class PetCreationResult {
  const PetCreationResult({
    required this.id,
    this.uploadedPath,
    this.photoFailed = false,
  });

  final String id;
  final String? uploadedPath;
  final bool photoFailed;
}

abstract class PetRepository {
  Future<String?> ownerId();
  Future<List<PetEntity>> fetchPets({int limit = 50, int offset = 0});
  Future<void> deletePet(String petId);
  Future<PetCreationResult> createPet({
    required PetDraft draft,
  });
  Future<void> removePhoto(String path);
}
