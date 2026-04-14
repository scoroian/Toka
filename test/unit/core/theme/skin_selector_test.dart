import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_skin.dart';

void main() {
  test('AppSkin.v2 exists and SkinConfig.current is v2 by default', () {
    expect(AppSkin.values, contains(AppSkin.v2));
    expect(SkinConfig.current, AppSkin.v2);
  });

  test('SkinConfig.current can be changed to material', () {
    SkinConfig.current = AppSkin.material;
    expect(SkinConfig.current, AppSkin.material);
    SkinConfig.current = AppSkin.v2; // restore
  });
}
