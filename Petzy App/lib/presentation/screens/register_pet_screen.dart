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

class _RegisterPetScreenState extends ConsumerState<RegisterPetScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  String _selectedSpecies = 'Perro';
  String? _selectedSex;
  String? _selectedSize;

  DateTime? _birthDate;
  File? _selectedImage;

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // ============================================================
  // FOTO
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (pickedFile == null) return;

      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    } catch (e) {
      _showError('No se pudo seleccionar la imagen.');
    }
  }

  // ============================================================
  // FECHA DE NACIMIENTO
  // ============================================================

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();

    final initialDate = _birthDate ?? DateTime(
      now.year - 2,
      now.month,
      now.day,
    );

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1990),
      lastDate: now,
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (selectedDate == null) return;

    setState(() {
      _birthDate = selectedDate;
    });
  }

  // ============================================================
  // FORMATO FECHA
  // ============================================================

  String _formatBirthDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // EDAD PARA MOSTRAR EN PANTALLA
  // ============================================================

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

  // ============================================================
  // OBTENER OWNER
  // ============================================================

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

  // ============================================================
  // GUARDAR MASCOTA
  // ============================================================

  Future<void> _onSavePet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      _showError('Tu sesión ha expirado. Inicia sesión nuevamente.');
      return;
    }

    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final supabase = Supabase.instance.client;

    String? petId;
    String? uploadedPath;

    try {
      // ----------------------------------------------------------
      // 1. Obtener owners.id
      // ----------------------------------------------------------

      final ownerId = await _getOwnerId(
        supabase,
        authUser.id,
      );

      // ----------------------------------------------------------
      // 2. Preparar datos de la mascota
      // ----------------------------------------------------------

      final Map<String, dynamic> petData = {
        'owner_id': ownerId,
        'name': _nameController.text.trim(),
        'species': _selectedSpecies,
      };

      final breed = _breedController.text.trim();

      if (breed.isNotEmpty) {
        petData['breed'] = breed;
      }

      if (_selectedSex != null) {
        petData['sex'] = _selectedSex;
      }

      if (_birthDate != null) {
        petData['birth_date'] =
            _birthDate!.toIso8601String().split('T').first;
      }

      final weightText = _weightController.text.trim();

      if (weightText.isNotEmpty) {
        final weight = double.tryParse(
          weightText.replaceAll(',', '.'),
        );

        if (weight == null || weight <= 0) {
          throw Exception(
            'El peso debe ser un número válido mayor que 0.',
          );
        }

        petData['weight_kg'] = weight;
      }

      if (_selectedSize != null) {
        petData['size'] = _selectedSize;
      }

      // ----------------------------------------------------------
      // 3. Crear mascota
      // ----------------------------------------------------------

      final insertedPet = await supabase
          .from('pets')
          .insert(petData)
          .select('id')
          .single();

      petId = insertedPet['id'] as String;

      // ----------------------------------------------------------
      // 4. Subir fotografía si existe
      // ----------------------------------------------------------

      if (_selectedImage != null) {
        final extension = _getFileExtension(
          _selectedImage!.path,
        );

        uploadedPath =
            '${authUser.id}/$petId.$extension';

        await supabase.storage
            .from('pet-photos')
            .upload(
              uploadedPath,
              _selectedImage!,
              fileOptions: const FileOptions(
                upsert: false,
              ),
            );

        // --------------------------------------------------------
        // 5. Obtener URL pública
        // --------------------------------------------------------

        final photoUrl = supabase.storage
            .from('pet-photos')
          .getPublicUrl(uploadedPath);

        // --------------------------------------------------------
        // 6. Guardar URL en pets
        // --------------------------------------------------------

        await supabase
            .from('pets')
            .update({
              'photo_url': photoUrl,
            })
            .eq('id', petId);
      }

      // ----------------------------------------------------------
      // 7. Completar primer login
      // ----------------------------------------------------------

      await ref
          .read(authStateProvider.notifier)
          .completeFirstLogin();

      if (!mounted) return;

      // ----------------------------------------------------------
      // 8. Ir a Home
      // ----------------------------------------------------------

      // El router observa authStateProvider.
      // completeFirstLogin() cambia isFirstLogin a false,
      // por lo que GoRouter debe redirigir automáticamente.
    } catch (e) {
      // ----------------------------------------------------------
      // LIMPIEZA
      // ----------------------------------------------------------

      if (uploadedPath != null) {
        try {
          await supabase.storage
              .from('pet-photos')
              .remove([uploadedPath]);
        } catch (_) {
          // No ocultamos el error original.
        }
      }

      if (petId != null) {
        try {
          await supabase
              .from('pets')
              .delete()
              .eq('id', petId);
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

  // ============================================================
  // EXTENSIÓN DE ARCHIVO
  // ============================================================

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

  // ============================================================
  // MENSAJES DE ERROR
  // ============================================================

  String _friendlyErrorMessage(Object error) {
    final message = error.toString();

    if (message.contains('owners')) {
      return 'No encontramos tu perfil de propietario. '
          'Cierra sesión e inicia sesión nuevamente.';
    }

    if (message.contains('pets')) {
      return 'No se pudo guardar la mascota. '
          'Verifica los datos e inténtalo nuevamente.';
    }

    if (message.contains('pet-photos')) {
      return 'La mascota fue creada, pero no se pudo subir la foto.';
    }

    if (message.contains('duplicate')) {
      return 'Ya existe un archivo con ese nombre.';
    }

    return 'No pudimos guardar la mascota. Inténtalo nuevamente.';
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Mascota'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ------------------------------------------------
                // FOTO
                // ------------------------------------------------

                Center(
                  child: GestureDetector(
                    onTap: _isLoading ? null : _pickImage,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _selectedImage != null
                          ? Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 40,
                                  color:
                                      theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Presiona para subir\n'
                                  'o capturar',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // ESPECIE
                // ------------------------------------------------

                _sectionTitle('ESPECIE'),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: _speciesButton(
                        label: 'Perro',
                        icon: Icons.pets_outlined,
                        selected:
                            _selectedSpecies == 'Perro',
                        onTap: () {
                          setState(() {
                            _selectedSpecies = 'Perro';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _speciesButton(
                        label: 'Gato',
                        icon: Icons.pets,
                        selected:
                            _selectedSpecies == 'Gato',
                        onTap: () {
                          setState(() {
                            _selectedSpecies = 'Gato';
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // NOMBRE
                // ------------------------------------------------

                _sectionTitle('NOMBRE'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _nameController,
                  textCapitalization:
                      TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Rocky',
                    prefixIcon: Icon(
                      Icons.pets_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Ingresa el nombre de tu mascota';
                    }

                    if (value.trim().length < 2) {
                      return 'El nombre es demasiado corto';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // RAZA
                // ------------------------------------------------

                _sectionTitle('RAZA'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _breedController,
                  textCapitalization:
                      TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    hintText: 'Ej. Bulldog Francés',
                    prefixIcon: Icon(
                      Icons.category_outlined,
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // FECHA DE NACIMIENTO
                // ------------------------------------------------

                _sectionTitle('FECHA DE NACIMIENTO'),

                const SizedBox(height: 8),

                InkWell(
                  onTap:
                      _isLoading ? null : _selectBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Seleccionar fecha'
                          : '${_formatBirthDate(_birthDate!)} '
                            '(${_calculateAge(_birthDate!)})',
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // PESO
                // ------------------------------------------------

                _sectionTitle('PESO (KG)'),

                const SizedBox(height: 8),

                TextFormField(
                  controller: _weightController,
                  enabled: !_isLoading,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ej. 9.5',
                    suffixText: 'kg',
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                    ),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return null;
                    }

                    final weight = double.tryParse(
                      value.trim().replaceAll(',', '.'),
                    );

                    if (weight == null || weight <= 0) {
                      return 'Ingresa un peso válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // SEXO
                // ------------------------------------------------

                _sectionTitle('SEXO'),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedSex,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.wc_outlined,
                    ),
                  ),
                  hint: const Text('Seleccionar'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Macho',
                      child: Text('Macho'),
                    ),
                    DropdownMenuItem(
                      value: 'Hembra',
                      child: Text('Hembra'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSex = value;
                          });
                        },
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // TAMAÑO
                // ------------------------------------------------

                _sectionTitle('TAMAÑO'),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedSize,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.straighten_outlined,
                    ),
                  ),
                  hint: const Text('Seleccionar'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pequeño',
                      child: Text('Pequeño'),
                    ),
                    DropdownMenuItem(
                      value: 'Mediano',
                      child: Text('Mediano'),
                    ),
                    DropdownMenuItem(
                      value: 'Grande',
                      child: Text('Grande'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          setState(() {
                            _selectedSize = value;
                          });
                        },
                ),

                const SizedBox(height: 32),

                // ------------------------------------------------
                // GUARDAR
                // ------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed:
                        _isLoading ? null : _onSavePet,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Guardar Mascota',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPONENTES VISUALES
  // ============================================================

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
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}