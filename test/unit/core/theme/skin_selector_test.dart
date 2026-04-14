import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_skin.dart';

void main() {
  test('AppSkin.v2 existe y SkinConfig.current es v2 por defecto', () {
    expect(AppSkin.values, contains(AppSkin.v2));
    expect(SkinConfig.current, AppSkin.v2);
  });

  test('SkinConfig.current se puede cambiar a material', () {
    SkinConfig.current = AppSkin.material;
    expect(SkinConfig.current, AppSkin.material);
    SkinConfig.current = AppSkin.v2; // restore
  });
}
