import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/pet_provider.dart';
import 'owner_pets_screen.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> {
  int _selectedTab = 0;

  Future<void> _openPets() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const OwnerPetsScreen()),
    );

    if (mounted) {
      await _reloadPets();
    }
  }

  Future<void> _reloadPets() async {
    await ref.refresh(ownerPetsProvider.future).then<void>((_) {});
  }

  void _selectTab(int index) {
    if (index == 1) {
      _openPets();
      return;
    }

    setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);
    final firstName = (user?.name ?? 'Maria').split(' ').first;
    final petNames = ref.watch(ownerPetsProvider).maybeWhen(
          data: (pets) => pets.map((pet) => pet.name).toList(),
          orElse: () => const <String>[],
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F1),
      body: SafeArea(
        child: IndexedStack(
            index: _selectedTab == 0 ? 0 : 1,
          children: [
            _HomeContent(
              firstName: firstName,
              petNames: petNames,
              onPetsTap: _openPets,
            ),
            _OwnerTabPlaceholder(
              title: 'Perfil',
              icon: Icons.person_outline,
              message: 'Gestiona tus datos y preferencias.',
              action: () => ref.read(authControllerProvider.notifier).signOut(),
              actionLabel: 'Cerrar sesión',
            ),
          ],
        ),
      ),
      bottomNavigationBar: _OwnerNavigationBar(
        selectedIndex: _selectedTab,
        onSelected: _selectTab,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.firstName,
    required this.petNames,
    required this.onPetsTap,
  });

  final String firstName;
  final List<String> petNames;
  final Future<void> Function() onPetsTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 34),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¡Hola, $firstName! 👋', style: _OwnerText.muted(17)),
                  const SizedBox(height: 5),
                  Text('¿Qué necesita tu\npeludo hoy?',
                      style: _OwnerText.heading(24)),
                ],
              ),
            ),
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFE5A94D),
              child: Icon(Icons.person, size: 35, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 23),
        Builder(
          builder: (context) {
            final names = petNames;
            final count = names.length;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPetsTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      count == 0 ? _OwnerPalette.express : _OwnerPalette.teal,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _IconBubble(
                      icon: Icons.pets,
                      color: count == 0
                          ? _OwnerPalette.express
                          : const Color(0xFF2A7378),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count ${count == 1 ? 'mascota registrada' : 'mascotas registradas'}',
                            style: _OwnerText.white(17),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _petCareMessage(names),
                            style: _OwnerText.white(14),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.white, size: 30),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _petCareMessage(List<String> names) {
  if (names.isEmpty) {
    const emptyMessages = [
      'Registra tu primera mascota y prepárala para su próxima aventura',
      'Tu peludo está por llegar: agrega una mascota para comenzar',
      'Agrega una mascota y recibe cuidados pensados para ella',
      'Registra a tu compañero y encuentra el cuidado ideal',
    ];
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return emptyMessages[dayIndex % emptyMessages.length];
  }

  final petList = names.length == 1
      ? names.first
      : names.length == 2
          ? '${names[0]} y ${names[1]}'
          : '${names.take(names.length - 1).join(', ')} y ${names.last}';

  final messages = names.length == 1
      ? [
          '$petList está listo para sus cuidados',
          '$petList tiene ganas de dar un paseo',
          'Hoy es un buen día para consentir a $petList',
        ]
      : [
          '$petList están listos para sus cuidados',
          '$petList tienen ganas de dar un paseo',
          'Hoy es un buen día para consentir a $petList',
        ];

  final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
  return messages[dayIndex % messages.length];
}

class _OwnerNavigationBar extends StatelessWidget {
  const _OwnerNavigationBar(
      {required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      height: 86,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home'),
        NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Mis Mascotas'),
        NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil'),
      ],
    );
  }
}

class _OwnerTabPlaceholder extends StatelessWidget {
  const _OwnerTabPlaceholder(
      {required this.title,
      required this.icon,
      required this.message,
      this.action,
      this.actionLabel});

  final String title;
  final IconData icon;
  final String message;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: _OwnerPalette.teal),
            const SizedBox(height: 14),
            Text(title, style: _OwnerText.heading(22)),
            const SizedBox(height: 8),
            Text(message, style: _OwnerText.muted(15)),
            if (action != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: action, child: Text(actionLabel!)),
            ],
          ],
        ),
      );
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: color == _OwnerPalette.teal
              ? const Color(0xFFEAF5F5)
              : const Color(0xFFFFEEEA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: color, size: 32),
      );
}

class _OwnerPalette {
  static const teal = Color(0xFF145B60);
  static const express = Color(0xFFFF735F);
}

class _OwnerText {
  static TextStyle heading(double size) => TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF223033));
  static TextStyle muted(double size) =>
      TextStyle(fontSize: size, color: const Color(0xFF66777A), height: 1.28);
  static TextStyle white(double size) => TextStyle(
      fontSize: size, color: Colors.white, fontWeight: FontWeight.w700);
  static TextStyle price() => const TextStyle(
      fontSize: 15, color: _OwnerPalette.teal, fontWeight: FontWeight.w800);
      fontSize: 15, color: _OwnerPalette.teal, fontWeight: FontWeight.w800);
