import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

class RegisterPetScreen extends ConsumerStatefulWidget {
  const RegisterPetScreen({super.key});

  @override
  ConsumerState<RegisterPetScreen> createState() => _RegisterPetScreenState();
}

// ============================================================
// MODELO LOCAL DEL FORMULARIO
// ============================================================

class _PetFormData {
  final nameController = TextEditingController();
  final breedController = TextEditingController();
  final weightController = TextEditingController();
  final descriptionController = TextEditingController();
  final behavioralNotesController = TextEditingController();
  final medicalNotesController = TextEditingController();
  final allergiesController = TextEditingController();
  final medicationsController = TextEditingController();
  final emergencyInstructionsController = TextEditingController();

  String selectedSpecies = 'Perro';
  String? selectedSex;
  String? selectedSize;
  DateTime? birthDate;
  File? selectedImage;

  bool hasBehavioralCondition = false;
  bool hasMedicalCondition = false;
  bool hasAllergies = false;
  bool takesMedication = false;
  bool hasEmergencyInstructions = false;

  void dispose() {
    nameController.dispose();
    breedController.dispose();
    weightController.dispose();
    descriptionController.dispose();
    behavioralNotesController.dispose();
    medicalNotesController.dispose();
    allergiesController.dispose();
    medicationsController.dispose();
    emergencyInstructionsController.dispose();
  }
}

class _RegisteredPet {
  const _RegisteredPet({
    required this.name,
    required this.species,
    required this.breed,
    required this.age,
    this.photoUrl,
  });

  final String name;
  final String species;
  final String breed;
  final String age;
  final String? photoUrl;
}

// ============================================================
// SCREEN
// ============================================================

class _RegisterPetScreenState extends ConsumerState<RegisterPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final List<_PetFormData> _pets = [
    _PetFormData(),
  ];

  bool _isLoading = false;
  bool _isLoadingRegisteredPets = true;
  List<_RegisteredPet> _registeredPets = const [];

  @override
  void initState() {
    super.initState();
    _loadRegisteredPets();
  }

  @override
  void dispose() {
    for (final pet in _pets) {
      pet.dispose();
    }

    super.dispose();
  }

  // ==========================================================
  // FOTO
  // ==========================================================

  Future<void> _pickImage(_PetFormData pet) async {
    if (_isLoading) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return;

      setState(() {
        pet.selectedImage = File(pickedFile.path);
      });
    } catch (_) {
      _showError('No se pudo seleccionar la imagen.');
    }
  }

  // ==========================================================
  // FECHA DE NACIMIENTO
  // ==========================================================

  Future<void> _selectBirthDate(_PetFormData pet) async {
    if (_isLoading) return;

    final now = DateTime.now();

    final initialDate = pet.birthDate ??
        DateTime(
          now.year - 2,
          now.month,
          now.day,
        );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (selectedDate == null) return;

    setState(() {
      pet.birthDate = selectedDate;
    });
  }

  String _formatBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();

    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (now.day < birthDate.day) {
      months--;
    }

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      if (months > 0) {
        return '$years ${years == 1 ? 'año' : 'años'} '
            'y $months ${months == 1 ? 'mes' : 'meses'}';
      }

      return '$years ${years == 1 ? 'año' : 'años'}';
    }

    if (months <= 0) {
      return 'Menos de 1 mes';
    }

    return '$months ${months == 1 ? 'mes' : 'meses'}';
  }

  // ==========================================================
  // AGREGAR MASCOTA
  // ==========================================================

  void _addPet() {
    if (_isLoading) return;

    setState(() {
      _pets.add(_PetFormData());
    });
  }

  // ==========================================================
  // ELIMINAR MASCOTA
  // ==========================================================

  void _removePet(int index) {
    if (_isLoading) return;

    if (_pets.length <= 1) return;

    final pet = _pets.removeAt(index);
    pet.dispose();

    setState(() {});
  }

  // ==========================================================
  // OBTENER OWNER
  // ==========================================================

  Future<void> _loadRegisteredPets() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final supabase = Supabase.instance.client;
      final owner = await supabase
          .from('owners')
          .select('id')
          .eq('profile_id', user.id)
          .maybeSingle();

      if (owner == null || !mounted) return;

      final rows = await supabase
          .from('pets')
          .select('name, species, breed, birth_date, photo_url')
          .eq('owner_id', owner['id'])
          .order('created_at');

      if (!mounted) return;

      setState(() {
        _registeredPets = rows.map<_RegisteredPet>((row) {
          final birthDate = DateTime.tryParse(
            row['birth_date']?.toString() ?? '',
          );
          return _RegisteredPet(
            name: row['name']?.toString() ?? 'Sin nombre',
            species: row['species']?.toString() ?? 'Mascota',
            breed: row['breed']?.toString() ?? 'Raza no indicada',
            age: birthDate == null
                ? 'Edad no indicada'
                : _calculateAge(birthDate),
            photoUrl: row['photo_url']?.toString(),
          );
        }).toList();
      });
    } catch (_) {
      // El formulario sigue disponible aunque la lista no pueda cargarse.
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRegisteredPets = false;
        });
      }
    }
  }

  Future<String> _getOwnerId(
    SupabaseClient supabase,
    String profileId,
  ) async {
    final response = await supabase
        .from('owners')
        .select('id')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'No se encontró el perfil de propietario para este usuario.',
      );
    }

    final ownerId = response['id'];

    if (ownerId == null) {
      throw Exception(
        'El propietario no tiene un ID válido.',
      );
    }

    return ownerId as String;
  }

  // ==========================================================
  // GUARDAR TODAS LAS MASCOTAS
  // ==========================================================

  Future<void> _onSavePets() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      _showError(
        'Tu sesión ha expirado. Inicia sesión nuevamente.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    final List<String> createdPetIds = [];
    final List<String> uploadedPaths = [];

    try {
      // --------------------------------------------------------
      // 1. Obtener owners.id
      // --------------------------------------------------------

      final ownerId = await _getOwnerId(
        supabase,
        authUser.id,
      );

      // --------------------------------------------------------
      // 2. Guardar cada mascota
      // --------------------------------------------------------

      for (final pet in _pets) {
        final Map<String, dynamic> petData = {
          'owner_id': ownerId,
          'name': pet.nameController.text.trim(),
          'species': pet.selectedSpecies,
        };

        // ------------------------------------------------------
        // RAZA
        // ------------------------------------------------------

        final breed = pet.breedController.text.trim();

        if (breed.isNotEmpty) {
          petData['breed'] = breed;
        }

        // ------------------------------------------------------
        // SEXO
        // ------------------------------------------------------

        if (pet.selectedSex != null) {
          petData['sex'] = pet.selectedSex;
        }

        // ------------------------------------------------------
        // FECHA DE NACIMIENTO
        // ------------------------------------------------------

        if (pet.birthDate != null) {
          petData['birth_date'] =
              pet.birthDate!.toIso8601String().split('T').first;
        }

        // ------------------------------------------------------
        // PESO
        // ------------------------------------------------------

        final weightText = pet.weightController.text.trim();

        if (weightText.isNotEmpty) {
          final weight = double.tryParse(
            weightText.replaceAll(',', '.'),
          );

          if (weight == null || weight <= 0) {
            throw Exception(
              'El peso de "${pet.nameController.text.trim()}" '
              'debe ser un número válido mayor que 0.',
            );
          }

          petData['weight_kg'] = weight;
        }

        // ------------------------------------------------------
        // TAMAÑO
        // ------------------------------------------------------

        if (pet.selectedSize != null) {
          petData['size'] = pet.selectedSize;
        }

        // ------------------------------------------------------
        // DESCRIPCIÓN
        // ------------------------------------------------------

        final description = pet.descriptionController.text.trim();

        if (description.isNotEmpty) {
          petData['description'] = description;
        }

        // ------------------------------------------------------
        // COMPORTAMIENTO
        // ------------------------------------------------------

        if (pet.hasBehavioralCondition) {
          final behavioralNotes = pet.behavioralNotesController.text.trim();

          if (behavioralNotes.isNotEmpty) {
            petData['behavioral_notes'] = behavioralNotes;
          }
        }

        // ------------------------------------------------------
        // CONDICIÓN MÉDICA
        // ------------------------------------------------------

        if (pet.hasMedicalCondition) {
          final medicalNotes = pet.medicalNotesController.text.trim();

          if (medicalNotes.isNotEmpty) {
            petData['medical_notes'] = medicalNotes;
          }
        }

        // ------------------------------------------------------
        // ALERGIAS
        // ------------------------------------------------------

        if (pet.hasAllergies) {
          final allergies = pet.allergiesController.text.trim();

          if (allergies.isNotEmpty) {
            petData['allergies'] = allergies;
          }
        }

        // ------------------------------------------------------
        // MEDICAMENTOS
        // ------------------------------------------------------

        if (pet.takesMedication) {
          final medications = pet.medicationsController.text.trim();

          if (medications.isNotEmpty) {
            petData['medications'] = medications;
          }
        }

        // ------------------------------------------------------
        // EMERGENCIA
        // ------------------------------------------------------

        if (pet.hasEmergencyInstructions) {
          final emergencyInstructions =
              pet.emergencyInstructionsController.text.trim();

          if (emergencyInstructions.isNotEmpty) {
            petData['emergency_instructions'] = emergencyInstructions;
          }
        }

        // ------------------------------------------------------
        // CREAR MASCOTA
        // ------------------------------------------------------

        final insertedPet =
            await supabase.from('pets').insert(petData).select('id').single();

        final petId = insertedPet['id'] as String;

        createdPetIds.add(petId);

        // ------------------------------------------------------
        // SUBIR FOTO
        // ------------------------------------------------------

        if (pet.selectedImage != null) {
          final extension = _getFileExtension(
            pet.selectedImage!.path,
          );

          final uploadedPath = '${authUser.id}/$petId.$extension';

          await supabase.storage.from('pet-photos').upload(
                uploadedPath,
                pet.selectedImage!,
                fileOptions: const FileOptions(
                  upsert: false,
                ),
              );

          uploadedPaths.add(uploadedPath);

          // ----------------------------------------------------
          // URL PÚBLICA
          // ----------------------------------------------------

          final photoUrl =
              supabase.storage.from('pet-photos').getPublicUrl(uploadedPath);

          // ----------------------------------------------------
          // GUARDAR URL
          // ----------------------------------------------------

          await supabase.from('pets').update({
            'photo_url': photoUrl,
          }).eq('id', petId);
        }
      }

      // --------------------------------------------------------
      // 3. Completar primer login
      // --------------------------------------------------------

      await ref.read(authStateProvider.notifier).completeFirstLogin();

      if (!mounted) return;

      _showSuccess(
        _pets.length == 1
            ? 'Mascota guardada correctamente.'
            : '${_pets.length} mascotas guardadas correctamente.',
      );

      // El router observa authStateProvider.
      // completeFirstLogin() cambia isFirstLogin a false
      // y GoRouter debe llevar al Home.
    } catch (e) {
      // --------------------------------------------------------
      // LIMPIEZA DE FOTOS
      // --------------------------------------------------------

      for (final uploadedPath in uploadedPaths) {
        try {
          await supabase.storage.from('pet-photos').remove([uploadedPath]);
        } catch (_) {
          // No ocultamos el error original.
        }
      }

      // --------------------------------------------------------
      // LIMPIEZA DE MASCOTAS
      // --------------------------------------------------------

      for (final petId in createdPetIds) {
        try {
          await supabase.from('pets').delete().eq('id', petId);
        } catch (_) {
          // No ocultamos el error original.
        }
      }

      if (!mounted) return;

      _showError(
        _friendlyErrorMessage(e),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================================
  // EXTENSIÓN DE ARCHIVO
  // ==========================================================

  String _getFileExtension(String path) {
    final fileName = path.split('/').last;

    if (!fileName.contains('.')) {
      return 'jpg';
    }

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'jpeg':
        return 'jpg';

      case 'jpg':
      case 'png':
      case 'webp':
        return extension;

      default:
        return 'jpg';
    }
  }

  // ==========================================================
  // MENSAJE DE ERROR
  // ==========================================================

  String _friendlyErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('owners')) {
      return 'No encontramos tu perfil de propietario. '
          'Cierra sesión e inicia sesión nuevamente.';
    }

    if (message.contains('pets')) {
      return 'No se pudieron guardar las mascotas. '
          'Verifica los datos e inténtalo nuevamente.';
    }

    if (message.contains('pet-photos')) {
      return 'Las mascotas fueron creadas, pero no se pudieron '
          'subir las fotografías.';
    }

    if (message.contains('duplicate')) {
      return 'Ya existe un archivo con ese nombre.';
    }

    return 'No pudimos guardar las mascotas. '
        'Inténtalo nuevamente.';
  }

  // ==========================================================
  // MENSAJES
  // ==========================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F4),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(36, 18, 36, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _roundIconButton(
                      icon: Icons.arrow_back,
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Text(
                        'Mis Mascotas',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF273338),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF5F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_registeredPets.length + _pets.length} de ${_registeredPets.length + _pets.length}',
                        style: const TextStyle(
                          color: Color(0xFF0E5960),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'REGISTRADAS (${_registeredPets.length})',
                  style: const TextStyle(
                    color: Color(0xFF64777B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isLoadingRegisteredPets)
                  const LinearProgressIndicator(minHeight: 2)
                else
                  ..._registeredPets.map(_buildRegisteredPetTile),

                if (_registeredPets.isNotEmpty) const SizedBox(height: 20),

                // ------------------------------------------------
                // MASCOTAS
                // ------------------------------------------------

                for (int index = 0; index < _pets.length; index++) ...[
                  _buildPetCard(
                    index,
                    _pets[index],
                  ),
                  const SizedBox(height: 20),
                ],

                // ------------------------------------------------
                // AGREGAR MASCOTA
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _addPet,
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Agregar otra mascota',
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _saveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF273338),
          side: const BorderSide(color: Color(0xFFE5E1DC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredPetTile(_RegisteredPet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE5E1DC)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: pet.photoUrl == null || pet.photoUrl!.isEmpty
                ? Container(
                    width: 54,
                    height: 54,
                    color: const Color(0xFFE7E2DC),
                    child: const Icon(Icons.pets, color: Color(0xFF8B786B)),
                  )
                : Image.network(
                    pet.photoUrl!,
                    width: 54,
                    height: 54,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 54,
                      height: 54,
                      color: const Color(0xFFE7E2DC),
                      child: const Icon(Icons.pets, color: Color(0xFF8B786B)),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    color: Color(0xFF273338),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${pet.breed} • ${pet.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64777B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFE7FAF1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 18,
              color: Color(0xFF00C88A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _onSavePets,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0D5A61),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Guardar Mascota',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
      ),
    );
  }

  // ==========================================================
  // CARD DE MASCOTA
  // ==========================================================

  Widget _buildPetCard(
    int index,
    _PetFormData pet,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 19, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0D5A61),
          width: 1.6,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------
          // HEADER
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Text(
                  'Nueva Mascota (${_registeredPets.length + index + 1})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0D5A61),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                'EN CURSO',
                style: TextStyle(
                  color: Color(0xFFFF665E),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_pets.length > 1)
                IconButton(
                  tooltip: 'Eliminar mascota',
                  onPressed: _isLoading ? null : () => _removePet(index),
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 18),

          // ------------------------------------------------------
          // FOTO
          // ------------------------------------------------------

          GestureDetector(
            onTap: _isLoading ? null : () => _pickImage(pet),
            child: Container(
              width: double.infinity,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF0D5A61)),
                color: const Color(0xFFEAF5F6),
              ),
              clipBehavior: Clip.antiAlias,
              child: pet.selectedImage != null
                  ? Image.file(pet.selectedImage!, fit: BoxFit.cover)
                  : Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF0D5A61),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Foto de ${pet.nameController.text.trim().isEmpty ? 'tu mascota' : pet.nameController.text.trim()}',
                              style: const TextStyle(
                                color: Color(0xFF0D5A61),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Presiona para subir o capturar',
                              style: TextStyle(
                                color: Color(0xFF64777B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 18),

          _sectionTitle('ESPECIE'),

          Row(
            children: [
              Expanded(
                child: _speciesButton(
                  label: 'Perro',
                  icon: Icons.pets_outlined,
                  selected: pet.selectedSpecies == 'Perro',
                  onTap: () {
                    setState(() {
                      pet.selectedSpecies = 'Perro';
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _speciesButton(
                  label: 'Gato',
                  icon: Icons.pets,
                  selected: pet.selectedSpecies == 'Gato',
                  onTap: () {
                    setState(() {
                      pet.selectedSpecies = 'Gato';
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ------------------------------------------------------
          // NOMBRE
          // ------------------------------------------------------

          _sectionTitle('NOMBRE'),
          const SizedBox(height: 8),

          TextFormField(
            controller: pet.nameController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej. Rocky',
              prefixIcon: Icon(
                Icons.pets_outlined,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ingresa el nombre de tu mascota';
              }

              if (value.trim().length < 2) {
                return 'El nombre es demasiado corto';
              }

              return null;
            },
          ),

          const SizedBox(height: 22),

          // ------------------------------------------------------
          // RAZA
          // ------------------------------------------------------

          _sectionTitle('RAZA'),
          const SizedBox(height: 8),

          TextFormField(
            controller: pet.breedController,
            enabled: !_isLoading,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Ej. Bulldog Francés',
              prefixIcon: Icon(
                Icons.category_outlined,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // ------------------------------------------------------
          // EDAD Y PESO
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: _sectionTitle('EDAD'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _sectionTitle('PESO (KG)'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InkWell(
                  onTap: _isLoading ? null : () => _selectBirthDate(pet),
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(
                      pet.birthDate == null
                          ? 'Seleccionar'
                          : _calculateAge(pet.birthDate!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: pet.weightController,
                  enabled: !_isLoading,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: '9.5',
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final weight = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (weight == null || weight <= 0) {
                      return 'Peso inválido';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            pet.birthDate == null
                ? 'Selecciona la edad para abrir el calendario de nacimiento'
                : 'Nacimiento: ${_formatBirthDate(pet.birthDate!)}',
            style: const TextStyle(
              color: Color(0xFF64777B),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 14),

          ExpansionTile(
            initiallyExpanded: false,
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            shape: const Border(),
            collapsedShape: const Border(),
            title: const Text(
              'Información adicional',
              style: TextStyle(
                color: Color(0xFF0D5A61),
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: const Text('Sexo, tamaño, descripción y cuidados'),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('SEXO'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: pet.selectedSex,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.wc_outlined),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 36,
                              minHeight: 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          hint: const Text(
                            'Seleccionar',
                            overflow: TextOverflow.ellipsis,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Macho',
                              child: Text(
                                'Macho',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Hembra',
                              child: Text(
                                'Hembra',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    pet.selectedSex = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('TAMAÑO'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: pet.selectedSize,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.straighten_outlined),
                            prefixIconConstraints: BoxConstraints(
                              minWidth: 36,
                              minHeight: 24,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 14,
                            ),
                          ),
                          hint: const Text(
                            'Seleccionar',
                            overflow: TextOverflow.ellipsis,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Pequeño',
                              child: Text(
                                'Pequeño',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Mediano',
                              child: Text(
                                'Mediano',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Grande',
                              child: Text(
                                'Grande',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: _isLoading
                              ? null
                              : (value) {
                                  setState(() {
                                    pet.selectedSize = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ------------------------------------------------------
              // DESCRIPCIÓN
              // ------------------------------------------------------

              _sectionTitle('DESCRIPCIÓN'),
              const SizedBox(height: 8),

              TextFormField(
                controller: pet.descriptionController,
                enabled: !_isLoading,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Cuéntanos un poco sobre tu mascota...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      bottom: 48,
                    ),
                    child: Icon(
                      Icons.notes_outlined,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------------
              // INFORMACIÓN PARA EL CUIDADOR
              // ------------------------------------------------------

              Text(
                'Información para el cuidador',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Esta información ayudará al cuidador a '
                'conocer mejor a tu mascota.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // COMPORTAMIENTO
              // ------------------------------------------------------

              _yesNoQuestion(
                title: '¿Tiene alguna condición de comportamiento que '
                    'el cuidador deba conocer?',
                value: pet.hasBehavioralCondition,
                onChanged: (value) {
                  setState(() {
                    pet.hasBehavioralCondition = value;

                    if (!value) {
                      pet.behavioralNotesController.clear();
                    }
                  });
                },
              ),

              if (pet.hasBehavioralCondition) ...[
                const SizedBox(height: 12),
                _conditionalTextField(
                  controller: pet.behavioralNotesController,
                  hintText: 'Ej. Tiene miedo a otros perros...',
                  icon: Icons.psychology_outlined,
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // CONDICIÓN MÉDICA
              // ------------------------------------------------------

              _yesNoQuestion(
                title: '¿Tiene alguna condición médica?',
                value: pet.hasMedicalCondition,
                onChanged: (value) {
                  setState(() {
                    pet.hasMedicalCondition = value;

                    if (!value) {
                      pet.medicalNotesController.clear();
                    }
                  });
                },
              ),

              if (pet.hasMedicalCondition) ...[
                const SizedBox(height: 12),
                _conditionalTextField(
                  controller: pet.medicalNotesController,
                  hintText: 'Indica la condición médica...',
                  icon: Icons.health_and_safety_outlined,
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // ALERGIAS
              // ------------------------------------------------------

              _yesNoQuestion(
                title: '¿Tiene alguna alergia?',
                value: pet.hasAllergies,
                onChanged: (value) {
                  setState(() {
                    pet.hasAllergies = value;

                    if (!value) {
                      pet.allergiesController.clear();
                    }
                  });
                },
              ),

              if (pet.hasAllergies) ...[
                const SizedBox(height: 12),
                _conditionalTextField(
                  controller: pet.allergiesController,
                  hintText: 'Ej. Alérgico al pollo...',
                  icon: Icons.warning_amber_outlined,
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // MEDICAMENTOS
              // ------------------------------------------------------

              _yesNoQuestion(
                title: '¿Toma algún medicamento?',
                value: pet.takesMedication,
                onChanged: (value) {
                  setState(() {
                    pet.takesMedication = value;

                    if (!value) {
                      pet.medicationsController.clear();
                    }
                  });
                },
              ),

              if (pet.takesMedication) ...[
                const SizedBox(height: 12),
                _conditionalTextField(
                  controller: pet.medicationsController,
                  hintText: 'Indica medicamento, dosis y frecuencia...',
                  icon: Icons.medication_outlined,
                  minLines: 3,
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------------
              // EMERGENCIA
              // ------------------------------------------------------

              _yesNoQuestion(
                title: '¿Tiene instrucciones especiales para una emergencia?',
                value: pet.hasEmergencyInstructions,
                onChanged: (value) {
                  setState(() {
                    pet.hasEmergencyInstructions = value;

                    if (!value) {
                      pet.emergencyInstructionsController.clear();
                    }
                  });
                },
              ),

              if (pet.hasEmergencyInstructions) ...[
                const SizedBox(height: 12),
                _conditionalTextField(
                  controller: pet.emergencyInstructionsController,
                  hintText: 'Indica qué debe hacer el cuidador...',
                  icon: Icons.emergency_outlined,
                  minLines: 3,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // PREGUNTA SI / NO
  // ==========================================================

  Widget _yesNoQuestion({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _answerButton(
                  label: 'No',
                  selected: !value,
                  onTap: () => onChanged(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _answerButton(
                  label: 'Sí',
                  selected: value,
                  onTap: () => onChanged(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BOTÓN SÍ / NO
  // ==========================================================

  Widget _answerButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // CAMPO CONDICIONAL
  // ==========================================================

  Widget _conditionalTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int minLines = 2,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      minLines: minLines,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            bottom: minLines > 2 ? 48 : 24,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }

  // ==========================================================
  // TÍTULO DE SECCIÓN
  // ==========================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }

  // ==========================================================
  // BOTÓN DE ESPECIE
  // ==========================================================

  Widget _speciesButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
