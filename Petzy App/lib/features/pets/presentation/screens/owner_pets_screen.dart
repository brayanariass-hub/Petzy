import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/pet_entity.dart';
import '../providers/pet_provider.dart';
import 'register_pet_screen.dart';

class OwnerPetsScreen extends ConsumerStatefulWidget {
  const OwnerPetsScreen({super.key});

  @override
  ConsumerState<OwnerPetsScreen> createState() => _OwnerPetsScreenState();
}

class _OwnerPetsScreenState extends ConsumerState<OwnerPetsScreen> {
  String? _deletingPetId;

  _PetSummary _toSummary(PetEntity pet) => _PetSummary(
        id: pet.id,
        name: pet.name,
        species: pet.species,
        breed: pet.breed ?? 'Raza no indicada',
        age: pet.birthDate == null
            ? 'Edad no indicada'
            : _formatAge(pet.birthDate!),
        photoUrl: pet.photoUrl,
      );

  String _formatAge(DateTime birthDate) {
    final now = DateTime.now();
    var years = now.year - birthDate.year;
    if (DateTime(now.year, birthDate.month, birthDate.day).isAfter(now)) {
      years--;
    }
    return years <= 0
        ? 'Menos de 1 año'
        : '$years ${years == 1 ? 'año' : 'años'}';
  }

  Future<void> _addPet() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const RegisterPetScreen(returnToPets: true),
      ),
    );

    if (!mounted) return;

    await _reloadPets();

    if (!mounted) return;

    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mascotas guardadas correctamente.')),
      );
    }
  }

  Future<void> _refreshPets() async {
    await _reloadPets();
  }

  Future<void> _reloadPets() {
    return ref.read(ownerPetsProvider.notifier).loadPets();
  }

  Future<void> _confirmDeletePet(_PetSummary pet) async {
    if (_deletingPetId != null || pet.id.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar mascota?'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${pet.name}? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9534F),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _deletingPetId = pet.id);

    try {
      await ref.read(ownerPetsProvider.notifier).deletePet(pet.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingPetId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo eliminar la mascota.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _deletingPetId = null);

    try {
      await _reloadPets();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${pet.name} fue eliminada. Actualiza la lista.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${pet.name} fue eliminada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Mis Mascotas',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ref.watch(ownerPetsProvider).when(
        loading: () {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF145B60)));
        },
        error: (error, stackTrace) {
          return _PetsMessage(
            icon: Icons.cloud_off,
            text: 'No pudimos cargar tus mascotas.',
            action: _loadAgain,
          );
        },
        data: (petEntities) {
          final pets = petEntities.map(_toSummary).toList();

          if (pets.isEmpty) {
            return _PetsMessage(
              icon: Icons.pets,
              text: 'Todavía no tienes mascotas registradas.',
              action: _addPet,
              actionLabel: 'Registrar mascota',
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF145B60),
            onRefresh: _refreshPets,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 100),
              itemCount: pets.length,
              itemBuilder: (context, index) => _PetCard(
                pet: pets[index],
                isDeleting: _deletingPetId == pets[index].id,
                onDelete: () => _confirmDeletePet(pets[index]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPet,
        backgroundColor: const Color(0xFF145B60),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar mascota'),
      ),
    );
  }

  Future<void> _loadAgain() => _refreshPets();
}

class _PetSummary {
  const _PetSummary(
      {required this.id,
      required this.name,
      required this.species,
      required this.breed,
      required this.age,
      this.photoUrl});
  final String id;
  final String name;
  final String species;
  final String breed;
  final String age;
  final String? photoUrl;
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.pet,
    required this.isDeleting,
    required this.onDelete,
  });
  final _PetSummary pet;
  final bool isDeleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE6E1DA)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: pet.photoUrl == null
                  ? Container(
                      width: 76,
                      height: 76,
                      color: const Color(0xFFEAF5F5),
                      child: const Icon(Icons.pets,
                          size: 36, color: Color(0xFF145B60)),
                    )
                  : Image.network(
                      pet.photoUrl!,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 76,
                        height: 76,
                        color: const Color(0xFFEAF5F5),
                        child: const Icon(Icons.pets,
                            size: 36, color: Color(0xFF145B60)),
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name,
                      style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF223033))),
                  const SizedBox(height: 5),
                  Text('${pet.species} · ${pet.breed}',
                      style: const TextStyle(color: Color(0xFF66777A))),
                  const SizedBox(height: 4),
                  Text(pet.age,
                      style: const TextStyle(
                          color: Color(0xFF145B60),
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            isDeleting
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    tooltip: 'Eliminar ${pet.name}',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: const Color(0xFFD9534F),
                  ),
          ],
        ),
      ),
    );
  }
}

class _PetsMessage extends StatelessWidget {
  const _PetsMessage(
      {required this.icon,
      required this.text,
      required this.action,
      this.actionLabel = 'Reintentar'});
  final IconData icon;
  final String text;
  final VoidCallback action;
  final String actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: const Color(0xFF145B60)),
              const SizedBox(height: 16),
              Text(text,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 16, color: Color(0xFF66777A))),
              const SizedBox(height: 20),
              FilledButton(onPressed: action, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}
