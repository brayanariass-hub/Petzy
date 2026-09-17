import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petzy/core/constants/supabase_constants.dart';
import 'package:petzy/domain/entities/user_entity.dart';
import 'package:petzy/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Supabase Auth Configuration & State Tests', () {
    test('SupabaseConstants has valid project URL and publishable key', () {
      expect(SupabaseConstants.supabaseUrl,
          equals('https://zbuafdyohmnrgssvgedu.supabase.co'));
      expect(SupabaseConstants.supabasePublishableKey,
          equals('sb_publishable_XuGXrZT1Psku6tEuFrbR2A_tKNiEC2c'));
    });

    test('Initial authStateProvider is null before login', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final user = container.read(authStateProvider);
      expect(user, isNull);
    });

    test('authStateProvider updates and persists user session correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const testUser = UserEntity(
        id: 'u-12345',
        name: 'Lina Gómez',
        email: 'lina@petzy.com',
        role: UserRole.owner,
        isFirstLogin: true,
      );

      container.read(authStateProvider.notifier).setUser(testUser);

      final user = container.read(authStateProvider);
      expect(user, isNotNull);
      expect(user?.id, equals('u-12345'));
      expect(user?.name, equals('Lina Gómez'));
      expect(user?.email, equals('lina@petzy.com'));
      expect(user?.role, equals(UserRole.owner));
      expect(user?.isFirstLogin, equals(true));

      // Test sign out state clearing
      container.read(authStateProvider.notifier).setUser(null);
      expect(container.read(authStateProvider), isNull);
    });
  });
}
