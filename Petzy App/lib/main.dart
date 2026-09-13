void main() {
  runApp(const ProviderScope(child: PetzyApp()));
}

class PetzyApp extends ConsumerWidget {
  const PetzyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Petzy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}