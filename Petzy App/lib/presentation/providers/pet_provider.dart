import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/pet_entity.dart';

final ownerPetsProvider = FutureProvider<List<PetEntity>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final supabase = Supabase.instance.client;
  final owner = await supabase
      .from('owners')
      .select('id')
      .eq('profile_id', user.id)
      .maybeSingle();

  if (owner == null) return [];

  final rows = await supabase
      .from('pets')
      .select(
        'id, owner_id, name, species, breed, sex, birth_date, weight_kg, '
        'size, photo_url, description, behavioral_notes, medical_notes, '
        'allergies, medications, emergency_instructions',
      )
      .eq('owner_id', owner['id'])
      .order('created_at');

  return rows.map<PetEntity>((row) {
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
      photoUrl: row['photo_url']?.toString(),
      description: row['description']?.toString(),
      behavioralNotes: row['behavioral_notes']?.toString(),
      medicalNotes: row['medical_notes']?.toString(),
      allergies: row['allergies']?.toString(),
      medications: row['medications']?.toString(),
      emergencyInstructions: row['emergency_instructions']?.toString(),
    );
  }).toList();
});
