import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/theme_mode_provider.dart';

/// Espera a que el provider emita un valor distinto de [ThemeMode.system].
/// Si transcurre el [timeout] sin cambio, devuelve el estado actual.
Future<ThemeMode> waitForStateChange(
  ProviderContainer container, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final completer = Completer<ThemeMode>();
  final sub = container.listen<ThemeMode>(
    themeModeNotifierProvider,
    (prev, next) {
      if (!completer.isCompleted) completer.complete(next);
    },
    fireImmediately: false,
  );
  try {
    return await completer.future.timeout(timeout);
  } catch (_) {
    return container.read(themeModeNotifierProvider);
  } finally {
    sub.close();
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('estado inicial es ThemeMode.system', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(themeModeNotifierProvider), ThemeMode.system);
  });

  test('setMode(light) actualiza estado y persiste', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Inicializar y esperar que _load termine (prefs vacíos → state queda system)
    container.read(themeModeNotifierProvider);
    await Future.delayed(const Duration(milliseconds: 100));

    await container.read(themeModeNotifierProvider.notifier).setMode(ThemeMode.light);
    expect(container.read(themeModeNotifierProvider), ThemeMode.light);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode_v2'), 'light');
  });

  test('_load restaura el modo guardado', () async {
    SharedPreferences.setMockInitialValues({'theme_mode_v2': 'dark'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Leer para inicializar el provider; waitForStateChange escucha el cambio
    container.read(themeModeNotifierProvider);
    final result = await waitForStateChange(container);
    expect(result, ThemeMode.dark);
  });

  test('_load sin clave guardada usa ThemeMode.system', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(themeModeNotifierProvider);
    // Sin clave guardada el estado no cambia de system
    await Future.delayed(const Duration(milliseconds: 100));
    expect(container.read(themeModeNotifierProvider), ThemeMode.system);
  });
}
