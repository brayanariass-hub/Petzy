import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/repositories/auth_repository.dart';
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
  static const Color _accentOrange = Color(0xFFFF6B53);
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

    final success =
        await ref.read(authControllerProvider.notifier).signInWithEmail(
              email: _emailController.text,
              password: _passwordController.text,
            );

    if (!mounted || success) return;

    final message = ref.read(authControllerProvider).errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _onResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa tu correo para recuperar la contraseña')),
      );
      return;
    }

    final success =
        await ref.read(authControllerProvider.notifier).resetPassword(email);
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Revisa tu correo para restablecer la contraseña.'
            : authState.errorMessage ?? 'No se pudo enviar el correo.'),
      ),
    );
  }

  Future<void> _onSocialLogin(SocialProvider provider) async {
    try {
      await ref.read(authControllerProvider.notifier).signInWithOAuth(provider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: _textMain),
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.email_outlined, color: _textMuted, size: 20),
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
                  border:
                      Border.all(color: Colors.black.withValues(alpha: 0.06)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: _textMain),
                  decoration: InputDecoration(
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Olvidaste contraseña
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onResetPassword,
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

              ElevatedButton(
                onPressed: authState.isLoading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerDark,
                  disabledBackgroundColor: _headerDark.withValues(alpha: 0.6),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                        'Iniciar Sesión',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),

              const SizedBox(height: 28),

              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE5E1DB))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      'o ingresa con',
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE5E1DB))),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _onSocialLogin(SocialProvider.google),
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFFEA4335),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      label: const Text('Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMain,
                        backgroundColor: _cardBg,
                        minimumSize: const Size(0, 44),
                        side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.apple, size: 20),
                      label: const Text('Apple'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMain,
                        backgroundColor: _cardBg,
                        minimumSize: const Size(0, 44),
                        side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.08)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Registrarse

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
                        color: _accentOrange,
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
