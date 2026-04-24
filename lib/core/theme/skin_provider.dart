import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_skin.dart';

part 'skin_provider.g.dart';

/// Skin visual activo de la app.
///
/// Persiste la preferencia del usuario en SharedPreferences bajo la clave
/// `tocka.skin` (guarda el nombre del enum). `keepAlive` evita reinicios al
/// navegar.
///
/// Consistente con `ThemeModeNotifier`: la carga async no bloquea el primer
/// frame; `build()` devuelve `AppSkin.v2` mientras se lee el storage y se
/// actualiza con `state = ...` cuando llega el valor persistido.
@Riverpod(keepAlive: true)
class SkinMode extends _$SkinMode {
  static const String persistKey = 'tocka.skin';

  @override
  AppSkin build() {
    Future.microtask(_load);
    return AppSkin.v2;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(persistKey);
      final match = AppSkin.values.firstWhere(
        (s) => s.persistKey == raw,
        orElse: () => AppSkin.v2,
      );
      if (match != state) state = match;
    } catch (e) {
      debugPrint('[SkinMode] load failed, staying on v2: $e');
    }
  }

  Future<void> set(AppSkin skin) async {
    state = skin;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(persistKey, skin.persistKey);
    } catch (e) {
      debugPrint('[SkinMode] persist failed (ui state already updated): $e');
    }
  }
}
