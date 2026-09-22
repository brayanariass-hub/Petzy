import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'owner_home_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    if (user?.role == UserRole.owner) {
      return const OwnerHomeScreen();
    }

    final bookingsState = ref.watch(bookingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de sitter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          )
        ],
      ),
      body: bookingsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Text('No tienes reservas activas',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final item = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.secondary,
                    child: Icon(Icons.pets, color: Colors.white),
                  ),
                  title: Text('Reserva #${item.id}'),
                  subtitle: Text('Estado: ${item.status.name.toUpperCase()}'),
                  trailing: Text('\$${item.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
