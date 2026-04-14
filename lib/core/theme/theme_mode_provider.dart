// lib/core/theme/theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_provider.g.dart';

const _kKey = 'theme_mode_v2';

@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    Future.microtask(_load);
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kKey);
    if (v == 'light') {
      state = ThemeMode.light;
    } else if (v == 'dark') {
      state = ThemeMode.dark;
    } else {
      state = ThemeMode.system;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark  => 'dark',
      _               => 'system',
    });
  }
}
