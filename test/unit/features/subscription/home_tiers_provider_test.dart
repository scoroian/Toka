import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/application/home_tiers_provider.dart';

void main() {
  group('homeTiersEnabledProvider', () {
    test('sin Firebase (entorno de test) → false (fail-safe OFF)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(homeTiersEnabledProvider), isFalse);
    });

    test('overridable a true para tests de UI', () {
      final container = ProviderContainer(
        overrides: [homeTiersEnabledProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      expect(container.read(homeTiersEnabledProvider), isTrue);
    });
  });
}
