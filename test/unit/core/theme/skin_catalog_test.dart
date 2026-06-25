import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_catalog.dart';

void main() {
  group('skinTier', () {
    test('v2 es gratuita', () {
      expect(skinTier(AppSkin.v2), SkinTier.free);
      expect(isPlusSkin(AppSkin.v2), isFalse);
    });

    test('oceano es cosmética Plus', () {
      expect(skinTier(AppSkin.oceano), SkinTier.plus);
      expect(isPlusSkin(AppSkin.oceano), isTrue);
    });
  });
}
