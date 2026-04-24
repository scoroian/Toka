import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SkinMode', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('build() returns v2 when SharedPreferences is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(skinModeProvider), AppSkin.v2);
      await Future.microtask(() {});
      expect(container.read(skinModeProvider), AppSkin.v2);
    });

    test('build() resolves to persisted value (futurista)', () async {
      SharedPreferences.setMockInitialValues({'tocka.skin': 'futurista'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // primer frame aún no ha cargado del storage
      expect(container.read(skinModeProvider), AppSkin.v2);

      // dejar correr microtask del _load
      await Future.delayed(Duration.zero);
      expect(container.read(skinModeProvider), AppSkin.futurista);
    });

    test('garbage in SharedPreferences falls back to v2', () async {
      SharedPreferences.setMockInitialValues({'tocka.skin': 'xyz'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future.delayed(Duration.zero);
      expect(container.read(skinModeProvider), AppSkin.v2);
    });

    test('set(futurista) updates state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Materializa el provider y deja que su _load() asíncrono termine antes
      // de llamar a set(), para evitar que el microtask de _load sobrescriba
      // el nuevo state con el valor persistido (vacío → v2).
      container.read(skinModeProvider);
      await Future.delayed(Duration.zero);

      await container.read(skinModeProvider.notifier).set(AppSkin.futurista);

      expect(container.read(skinModeProvider), AppSkin.futurista);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tocka.skin'), 'futurista');
    });
  });
}
