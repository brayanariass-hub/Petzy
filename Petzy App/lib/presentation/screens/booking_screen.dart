import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/booking_entity.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitar Cuidadores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    CircleAvatar(radius: 30, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white)),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('María López', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('⭐ 4.9 (48 servicios)', style: TextStyle(color: AppColors.textMuted)),
                        Text('\$15.00 / hora', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                try {
                  final newBooking = BookingEntity(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    petId: 'pet_1',
                    caregiverId: 'caregiver_1',
                    date: DateTime.now(),
                    status: BookingStatus.pending,
                    totalAmount: 15.0,
                  );
                  await ref.read(bookingNotifierProvider.notifier).addBooking(newBooking);
                  if (context.mounted) GoRouter.of(context).pop();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Confirmar Reserva'),
            ),
          ],
        ),
      ),
    );
  }
}