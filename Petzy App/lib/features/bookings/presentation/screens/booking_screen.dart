import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/create_booking_command.dart';
import '../providers/booking_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _petIdController = TextEditingController();
  final _serviceIdController = TextEditingController();
  DateTime _startAt = DateTime.now().add(const Duration(hours: 1));
  int _durationMinutes = 60;

  @override
  void dispose() {
    _petIdController.dispose();
    _serviceIdController.dispose();
    super.dispose();
  }

  Future<void> _selectStart() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _startAt,
    );
    if (!mounted || date == null) return;

    final time = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_startAt));
    if (!mounted || time == null) return;
    setState(() {
      _startAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    final command = CreateBookingCommand(
      petId: _petIdController.text.trim(),
      sitterServiceId: _serviceIdController.text.trim(),
      startAt: _startAt,
      durationMinutes: _durationMinutes,
    );

    try {
      await ref.read(bookingNotifierProvider.notifier).addBooking(command);
      if (mounted) context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  String? _requiredUuid(String? value, String label) {
    final uuid = value?.trim() ?? '';
    final pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$');
    if (!pattern.hasMatch(uuid)) return '$label debe ser un UUID válido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(bookingNotifierProvider).isLoading;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva reserva')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Datos de Supabase',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Usa los UUID reales de tu mascota, sitter y servicio.'),
            const SizedBox(height: 20),
            _uuidField(_petIdController, 'UUID de mascota', 'La mascota'),
            _uuidField(
                _serviceIdController, 'UUID del servicio', 'El servicio'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Inicio'),
              subtitle: Text(
                  '${_startAt.day}/${_startAt.month}/${_startAt.year} ${TimeOfDay.fromDateTime(_startAt).format(context)}'),
              trailing: const Icon(Icons.calendar_month),
              onTap: _selectStart,
            ),
            DropdownButtonFormField<int>(
              initialValue: _durationMinutes,
              decoration: const InputDecoration(labelText: 'Duración'),
              items: const [60, 120, 180, 240]
                  .map((minutes) => DropdownMenuItem(
                      value: minutes, child: Text('$minutes minutos')))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _durationMinutes = value ?? 60),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _createBooking,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Crear reserva'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uuidField(
      TextEditingController controller, String label, String errorLabel) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: (value) => _requiredUuid(value, errorLabel),
      ),
    );
  }
}
