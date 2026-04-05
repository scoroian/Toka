import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/i18n/domain/language.dart';

void main() {
  group('Language.fromFirestore', () {
    test('parses a full valid map', () {
      final data = {
        'code': 'es',
        'name': 'Español',
        'flag': '🇪🇸',
        'arb_key': 'app_es',
        'enabled': true,
        'sort_order': 1,
      };
      final lang = Language.fromFirestore(data);
      expect(lang.code, 'es');
      expect(lang.name, 'Español');
      expect(lang.flag, '🇪🇸');
      expect(lang.arbKey, 'app_es');
      expect(lang.enabled, true);
      expect(lang.sortOrder, 1);
    });

    test('uses default values when optional fields are absent', () {
      final data = {
        'code': 'en',
        'name': 'English',
        'flag': '🇬🇧',
        'arb_key': 'app_en',
      };
      final lang = Language.fromFirestore(data);
      expect(lang.enabled, true);
      expect(lang.sortOrder, 99);
    });
  });
}
