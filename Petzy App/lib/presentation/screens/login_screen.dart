import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/booking_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.pets, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Petzy',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.dark),
            ),
            const SizedBox(height: 8),
            const Text(
              'El Uber para el cuidado de tus mascotas',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                ref.read(authStateProvider.notifier).state = const UserEntity(
                  id: 'u1',
                  name: 'Carlos Ruiz',
                  email: 'carlos@petzy.com',
                  role: UserRole.owner,
                );
              },
              child: const Text('Iniciar Sesión como Dueño'),
            ),
          ],
        ),
      ),
    );
  }
}