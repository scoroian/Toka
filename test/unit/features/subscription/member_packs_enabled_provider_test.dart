import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/application/member_packs_enabled_provider.dart';

void main() {
  group('memberPacksEnabledProvider', () {
    test('sin Firebase (entorno de test) → false (fail-safe OFF)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(memberPacksEnabledProvider), isFalse);
    });

    test('overridable a true para tests de UI', () {
      final container = ProviderContainer(
        overrides: [memberPacksEnabledProvider.overrideWithValue(true)],
      );
      addTearDown(container.dispose);
      expect(container.read(memberPacksEnabledProvider), isTrue);
    });
  });
}
