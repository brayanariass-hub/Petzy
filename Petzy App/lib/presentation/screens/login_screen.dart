import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Paleta de colores extraída de la imagen UI
  static const Color _bgCanvas = Color(0xFFF9F7F2);
  static const Color _headerDark = Color(0xFF0F4C4F);
  static const Color _accentOrange = Color(0xFFE2725B);
  static const Color _textMain = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF6B7280);
  static const Color _cardBg = Colors.white;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu correo electrónico'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu contraseña'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (!success) {
      final errorMessage =
          ref.read(authControllerProvider).errorMessage ?? 'Error al iniciar sesión';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: _bgCanvas,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                height: 230,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: _headerDark,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Stack(
                  children: [
                    // Círculo decorativo superior izquierdo
                    Positioned(
                      top: -60,
                      left: -50,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Círculo decorativo inferior derecho
                    Positioned(
                      bottom: -80,
                      right: -40,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    // Contenido Header
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _accentOrange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Petzy',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cuidado premium en el que confías',
                            style: TextStyle(
                              fontSize: 13,
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

              const SizedBox(height: 28),

              // Textos de Bienvenida
              const Text(
                '¡Hola de nuevo!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _textMain,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inicia sesión para cuidar a tus seres más queridos.',
                style: TextStyle(
                  fontSize: 14,
                  color: _textMuted,
                ),
              ),

              const SizedBox(height: 24),

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
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: _textMain),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email_outlined, color: _textMuted, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: _textMain),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline, color: _textMuted, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.remove_red_eye_outlined : Icons.visibility_off_outlined,
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Olvidaste contraseña
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {},
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _accentOrange,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón Iniciar Sesión
              ElevatedButton(
                onPressed: authState.isLoading ? null : _onLogin,
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Divider "o ingresa con"
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'o ingresa con',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              // Botones Sociales
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.red, size: 26),
                      label: const Text(
                        'Google',
                        style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _cardBg,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, color: Colors.black, size: 22),
                      label: const Text(
                        'Apple',
                        style: TextStyle(color: _textMain, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _cardBg,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Registrarse
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¿No tienes una cuenta? ',
                    style: TextStyle(color: _textMuted, fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        color: _headerDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}