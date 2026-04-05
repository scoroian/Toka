import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  LocaleService({
    required SharedPreferences prefs,
    required FirebaseFirestore firestore,
    Locale? overrideDeviceLocale,
  })  : _prefs = prefs,
        _firestore = firestore,
        _overrideDeviceLocale = overrideDeviceLocale;

  static const _key = 'locale';
  static const fallback = Locale('es');
  static const supported = [Locale('es'), Locale('en'), Locale('ro')];

  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;
  final Locale? _overrideDeviceLocale;

  /// Returns the active locale.
  /// Priority: Firestore (uid) → SharedPreferences → device locale → fallback.
  Future<Locale> getCurrentLocale(String? uid) async {
    if (uid != null) {
      try {
        final doc = await _firestore.collection('users').doc(uid).get();
        final code = doc.data()?['locale'] as String?;
        if (code != null && code.isNotEmpty) {
          return Locale(code);
        }
      } catch (_) {
        // Fall through to SharedPreferences
      }
    }

    final savedCode = _prefs.getString(_key);
    if (savedCode != null && savedCode.isNotEmpty) {
      return Locale(savedCode);
    }

    final device = _overrideDeviceLocale ?? _resolveDeviceLocale();
    if (supported.contains(device)) {
      return device;
    }
    return fallback;
  }

  /// Saves the locale to SharedPreferences and, if a uid is provided, to Firestore.
  Future<void> saveLocale(String code, String? uid) async {
    await _prefs.setString(_key, code);
    if (uid != null) {
      await _firestore
          .collection('users')
          .doc(uid)
          .set({'locale': code}, SetOptions(merge: true));
    }
  }

  Locale _resolveDeviceLocale() {
    final languageCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return Locale(languageCode);
  }
}
