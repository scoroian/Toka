import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/effective_skin_provider.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/subscription/application/plus_provider.dart';

class _FakeSkinMode extends SkinMode {
  _FakeSkinMode(this._skin);
  final AppSkin _skin;
  @override
  AppSkin build() => _skin;
}

AppSkin _read({required AppSkin selected, required bool hasPlus}) {
  final container = ProviderContainer(overrides: [
    skinModeProvider.overrideWith(() => _FakeSkinMode(selected)),
    plusActiveProvider.overrideWithValue(hasPlus),
  ]);
  addTearDown(container.dispose);
  return container.read(effectiveSkinProvider);
}

void main() {
  group('effectiveSkinProvider', () {
    test('skin gratuita se respeta tenga o no Plus', () {
      expect(_read(selected: AppSkin.v2, hasPlus: false), AppSkin.v2);
      expect(_read(selected: AppSkin.v2, hasPlus: true), AppSkin.v2);
    });

    test('skin Plus se aplica si hay Plus', () {
      expect(_read(selected: AppSkin.oceano, hasPlus: true), AppSkin.oceano);
    });

    test('skin Plus cae a v2 si NO hay Plus (degradación)', () {
      expect(_read(selected: AppSkin.oceano, hasPlus: false), AppSkin.v2);
    });
  });
}
