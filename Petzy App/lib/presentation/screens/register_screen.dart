import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.owner;
  bool _isOAuthRegistration = false;

  // Paleta de colores acorde con el diseño de Petzy
  static const Color _bgCanvas = Color(0xFFF9F7F2);
  static const Color _headerDark = Color(0xFF0F4C4F);
  static const Color _accentOrange = Color(0xFFE2725B);
  static const Color _textMain = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final provider = user?.appMetadata['provider'];
    _isOAuthRegistration = provider == 'google' || provider == 'apple';
    if (_isOAuthRegistration && user != null) {
      final metadata = user.userMetadata ?? {};
      final fullName = (metadata['full_name'] as String?)?.trim() ?? '';
      final nameParts = fullName.split(RegExp(r'\s+'));
      _firstNameController.text = (metadata['first_name'] as String?)?.trim() ??
          (nameParts.isNotEmpty ? nameParts.first : '');
      _lastNameController.text = (metadata['last_name'] as String?)?.trim() ??
          (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
      _emailController.text = user.email ?? '';
      _phoneController.text = (metadata['phone'] as String?)?.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    // Cerrar teclado
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    final success = _isOAuthRegistration
        ? await authNotifier.completeOAuthProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          )
        : await authNotifier.signUpWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
            role: _selectedRole,
          );

    if (!mounted) return;

    final authState = ref.read(authControllerProvider);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authState.successMessage ?? '¡Cuenta creada con éxito!',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );

      // Si no hay sesión automática (requiere confirmación de email), navegar a login
      final currentUser = ref.read(authStateProvider);
      if (currentUser == null) {
        context.go('/login');
      }
    } else {
      if (authState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authState.errorMessage!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _cancelOAuthRegistration() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _textMain,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: keyboardType == TextInputType.phone
                ? TextCapitalization.none
                : TextCapitalization.words,
            style: const TextStyle(fontSize: 14, color: _textMain),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
              prefixIcon: Icon(icon, color: _textMuted, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card con botón volver y branding
                Container(
                  height: 190,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _headerDark,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: Stack(
                    children: [
                      // Círculo decorativo superior izquierdo
                      Positioned(
                        top: -50,
                        left: -40,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      // Círculo decorativo inferior derecho
                      Positioned(
                        bottom: -70,
                        right: -30,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      // Botón volver
                      Positioned(
                        top: 14,
                        left: 14,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/login');
                            }
                          },
                        ),
                      ),
                      // Contenido Header
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _accentOrange,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Crear Cuenta en Petzy',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Únete a la comunidad de amantes de mascotas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Textos de Bienvenida
                const Text(
                  'Regístrate',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Completa los siguientes datos para comenzar.',
                  style: TextStyle(
                    fontSize: 14,
                    color: _textMuted,
                  ),
                ),

                const SizedBox(height: 20),

                // Campos de nombre y apellido
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'NOMBRE',
                        controller: _firstNameController,
                        hintText: 'María',
                        icon: Icons.person_outline,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu nombre';
                          }
                          if (val.trim().length < 2) {
                            return 'Nombre muy corto';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        label: 'APELLIDO',
                        controller: _lastNameController,
                        hintText: 'Pérez',
                        icon: Icons.person_outline,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ingresa tu apellido';
                          }
                          if (val.trim().length < 2) {
                            return 'Apellido muy corto';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Campo Email
                const Text(
                  'CORREO ELECTRÓNICO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.black.withValues(alpha: 0.06)),
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, color: _textMain),
                    decoration: const InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 13),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: _textMuted, size: 20),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Por favor ingresa tu correo electrónico';
                      }
                      final emailRegExp =
                          RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegExp.hasMatch(val.trim())) {
                        return 'Ingresa un formato de correo válido';
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 16),

                _buildTextField(
                  label: 'TELÉFONO',
                  controller: _phoneController,
                  hintText: 'Ej. +57 300 123 4567',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Ingresa tu teléfono';
                    }
                    if (val.trim().length < 7) {
                      return 'Teléfono inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Selector de Rol
                const Text(
                  'TIPO DE CUENTA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textMain,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _RoleSelectionCard(
                        title: 'Dueño',
                        subtitle: 'Busco cuidados',
                        icon: Icons.pets_outlined,
                        isSelected: _selectedRole == UserRole.owner,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.owner),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleSelectionCard(
                        title: 'Cuidador',
                        subtitle: 'Ofrezco servicios',
                        icon: Icons.volunteer_activism_outlined,
                        isSelected: _selectedRole == UserRole.sitter,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.sitter),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!_isOAuthRegistration) ...[
                  // Campo Contraseña
                  const Text(
                    'CONTRASEÑA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _textMain,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 14, color: _textMain),
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        hintStyle:
                            const TextStyle(color: _textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_outline,
                            color: _textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.remove_red_eye_outlined
                                : Icons.visibility_off_outlined,
                            color: _textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (val.length < 6) {
                          return 'La contraseña debe tener al menos 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo Confirmar Contraseña
                  const Text(
                    'CONFIRMAR CONTRASEÑA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _textMain,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(fontSize: 14, color: _textMain),
                      decoration: InputDecoration(
                        hintText: 'Repite tu contraseña',
                        hintStyle:
                            const TextStyle(color: _textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.lock_reset_outlined,
                            color: _textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.remove_red_eye_outlined
                                : Icons.visibility_off_outlined,
                            color: _textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (val != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Botón Registrarse
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerDark,
                    disabledBackgroundColor: _headerDark.withValues(alpha: 0.6),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Enlace a Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta? ',
                      style: TextStyle(color: _textMuted, fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: _isOAuthRegistration
                          ? _cancelOAuthRegistration
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/login');
                              }
                            },
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: _headerDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color activeColor = Color(0xFF0F4C4F);
    const Color inactiveBorder = Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? activeColor.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : inactiveBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? activeColor : const Color(0xFF6B7280),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : const Color(0xFF1F2937),
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
