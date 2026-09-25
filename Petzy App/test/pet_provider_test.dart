import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petzy/features/pets/domain/entities/pet_entity.dart';
import 'package:petzy/features/pets/domain/entities/pet_draft.dart';
import 'package:petzy/features/pets/domain/repositories/pet_repository.dart';
import 'package:petzy/features/pets/presentation/providers/pet_provider.dart';

class FakePetRepository implements PetRepository {
  FakePetRepository(this.pets);

  List<PetEntity> pets;

  @override
  Future<String?> ownerId() async => 'owner-1';

  @override
  Future<List<PetEntity>> fetchPets({int limit = 50, int offset = 0}) async {
    return List<PetEntity>.from(pets.skip(offset).take(limit));
  }

  @override
  Future<void> deletePet(String petId) async {
    pets = pets.where((pet) => pet.id != petId).toList();
  }

  @override
  Future<PetCreationResult> createPet({
    required PetDraft draft,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removePhoto(String path) async {}
}

PetEntity pet(String id, String name) {
  return PetEntity(
    id: id,
    ownerId: 'owner-1',
    name: name,
    species: 'Perro',
  );
}

void main() {
  test('PetNotifier keeps its cache in sync after deleting a pet', () async {
    final repository = FakePetRepository([
      pet('pet-1', 'Luna'),
      pet('pet-2', 'Max'),
    ]);
    final notifier = PetNotifier(repository);
    addTearDown(notifier.dispose);

    await notifier.loadPets();
    expect(
        notifier.state.requireValue.map((item) => item.name), ['Luna', 'Max']);

    await notifier.deletePet('pet-1');

    expect(notifier.state.requireValue.map((item) => item.name), ['Max']);
  });
}
