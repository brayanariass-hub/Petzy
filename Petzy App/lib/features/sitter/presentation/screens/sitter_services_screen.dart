import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SitterServicesScreen extends ConsumerStatefulWidget {
  const SitterServicesScreen({super.key});

  @override
  ConsumerState<SitterServicesScreen> createState() =>
      _SitterServicesScreenState();
}

class _SitterServicesScreenState extends ConsumerState<SitterServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authStateProvider.notifier).completeFirstLogin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis servicios'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: const Center(
        child: Text('Aquí podrás gestionar tus servicios.'),
      ),
    );
  }
}
