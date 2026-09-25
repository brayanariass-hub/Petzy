import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';
import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/pet_draft.dart';
import '../../domain/repositories/pet_repository.dart';

class PetNotifier extends StateNotifier<AsyncValue<List<PetEntity>>> {
  PetNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPets();
  }

  final PetRepository _repository;

  Future<void> loadPets() async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repository.fetchPets());
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePet(String petId) async {
    await _repository.deletePet(petId);
    final currentPets =
        state.hasValue ? state.requireValue : const <PetEntity>[];
    state = AsyncValue.data(
      currentPets.where((pet) => pet.id != petId).toList(growable: false),
    );
  }

  Future<PetCreationResult> createPet({
    required PetDraft draft,
  }) async {
    final result = await _repository.createPet(draft: draft);
    await loadPets();
    return result;
  }
}

final ownerPetsProvider =
    StateNotifierProvider<PetNotifier, AsyncValue<List<PetEntity>>>((ref) {
  return PetNotifier(ref.watch(petRepositoryProvider));
});
