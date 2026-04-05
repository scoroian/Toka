import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/locale_service.dart';

part 'locale_provider.g.dart';

@Riverpod(keepAlive: true)
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Locale build() => LocaleService.fallback;

  Future<void> initialize(String? uid) async {
    final service = await _buildService();
    state = await service.getCurrentLocale(uid);
  }

  Future<void> setLocale(String code, String? uid) async {
    final service = await _buildService();
    await service.saveLocale(code, uid);
    state = Locale(code);
  }

  Future<LocaleService> _buildService() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleService(
      prefs: prefs,
      firestore: FirebaseFirestore.instance,
    );
  }
}
