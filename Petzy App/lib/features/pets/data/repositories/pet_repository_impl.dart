import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/pet_entity.dart';
import '../../domain/entities/pet_draft.dart';
import '../../domain/repositories/pet_repository.dart';

class SupabasePetRepository implements PetRepository {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<String?> ownerId() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final owner = await _supabase
        .from('owners')
        .select('id')
        .eq('profile_id', user.id)
        .maybeSingle();
    return owner?['id']?.toString();
  }

  @override
  Future<List<PetEntity>> fetchPets({int limit = 50, int offset = 0}) async {
    final resolvedOwnerId = await ownerId();
    if (resolvedOwnerId == null) return [];

    final rows = await _supabase
        .from('pets')
        .select(
          'id, owner_id, name, species, breed, sex, birth_date, weight_kg, '
          'size, photo_url, description, behavioral_notes, medical_notes, '
          'allergies, medications, emergency_instructions',
        )
        .eq('owner_id', resolvedOwnerId)
        .order('created_at')
        .range(offset, offset + limit - 1);

    return Future.wait(rows.map<Future<PetEntity>>((row) async {
      final storedPhotoPath = row['photo_url']?.toString();
      return PetEntity(
        id: row['id'].toString(),
        ownerId: row['owner_id'].toString(),
        name: row['name']?.toString() ?? 'Sin nombre',
        species: row['species']?.toString() ?? 'Mascota',
        breed: row['breed']?.toString(),
        sex: row['sex']?.toString(),
        birthDate: DateTime.tryParse(row['birth_date']?.toString() ?? ''),
        weightKg: (row['weight_kg'] as num?)?.toDouble(),
        size: row['size']?.toString(),
        photoUrl: storedPhotoPath == null
            ? null
            : await _signedPhotoUrl(storedPhotoPath),
        description: row['description']?.toString(),
        behavioralNotes: row['behavioral_notes']?.toString(),
        medicalNotes: row['medical_notes']?.toString(),
        allergies: row['allergies']?.toString(),
        medications: row['medications']?.toString(),
        emergencyInstructions: row['emergency_instructions']?.toString(),
      );
    }));
  }

  @override
  Future<void> deletePet(String petId) async {
    await _supabase.from('pets').delete().eq('id', petId);
  }

  @override
  Future<PetCreationResult> createPet({
    required PetDraft draft,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('Debes iniciar sesión para crear una mascota.');
    }

    final resolvedOwnerId = await ownerId();
    if (resolvedOwnerId == null) {
      throw const AuthException(
          'No se encontró el perfil de propietario autenticado.');
    }

    final data = <String, dynamic>{
      'owner_id': resolvedOwnerId,
      'name': draft.name,
      'species': draft.species,
      if (draft.breed != null) 'breed': draft.breed,
      if (draft.sex != null) 'sex': draft.sex,
      if (draft.birthDate != null)
        'birth_date': draft.birthDate!.toIso8601String().split('T').first,
      if (draft.weightKg != null) 'weight_kg': draft.weightKg,
      if (draft.size != null) 'size': draft.size,
      if (draft.description != null) 'description': draft.description,
      if (draft.behavioralNotes != null)
        'behavioral_notes': draft.behavioralNotes,
      if (draft.medicalNotes != null) 'medical_notes': draft.medicalNotes,
      if (draft.allergies != null) 'allergies': draft.allergies,
      if (draft.medications != null) 'medications': draft.medications,
      if (draft.emergencyInstructions != null)
        'emergency_instructions': draft.emergencyInstructions,
    };
    final insertedPet =
        await _supabase.from('pets').insert(data).select('id').single();
    final petId = insertedPet['id']?.toString();
    if (petId == null || petId.isEmpty) {
      throw Exception('La mascota se creó sin un ID válido.');
    }

    if (draft.imagePath == null) return PetCreationResult(id: petId);

    try {
      final image = File(draft.imagePath!);
      final extension = _fileExtension(draft.imagePath!);
      final uploadedPath = '${user.id}/$petId.$extension';
      await _supabase.storage.from('pet-photos').upload(
            uploadedPath,
            image,
            fileOptions: FileOptions(
              contentType: _contentType(extension),
              upsert: true,
            ),
          );
      await _supabase
          .from('pets')
          .update({'photo_url': uploadedPath}).eq('id', petId);
      return PetCreationResult(id: petId, uploadedPath: uploadedPath);
    } catch (_) {
      return PetCreationResult(id: petId, photoFailed: true);
    }
  }

  @override
  Future<void> removePhoto(String path) async {
    await _supabase.storage.from('pet-photos').remove([path]);
  }

  Future<String?> _signedPhotoUrl(String path) async {
    try {
      return await _supabase.storage.from('pet-photos').createSignedUrl(
            path,
            3600,
          );
    } catch (_) {
      return null;
    }
  }

  String _fileExtension(String path) {
    final extension = path.split('.').last.toLowerCase();
    return const {'jpeg', 'jpg', 'png', 'webp'}.contains(extension)
        ? (extension == 'jpeg' ? 'jpg' : extension)
        : 'jpg';
  }

  String _contentType(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
