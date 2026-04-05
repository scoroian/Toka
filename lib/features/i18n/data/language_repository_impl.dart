import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/language.dart';
import '../domain/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  LanguageRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  static const _defaults = [
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸', 'arb_key': 'app_es', 'enabled': true, 'sort_order': 1},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'arb_key': 'app_en', 'enabled': true, 'sort_order': 2},
    {'code': 'ro', 'name': 'Română',  'flag': '🇷🇴', 'arb_key': 'app_ro', 'enabled': true, 'sort_order': 3},
  ];

  @override
  Future<List<Language>> fetchAvailableLanguages() async {
    try {
      final snapshot = await _firestore
          .collection('languages')
          .where('enabled', isEqualTo: true)
          .orderBy('sort_order')
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => Language.fromFirestore(doc.data()))
            .toList();
      }

      // Colección vacía: devolver los defaults en memoria (sin escribir en
      // Firestore, ya que el cliente no tiene permiso de escritura).
      return _defaults.map(Language.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw LanguagesFetchException(e.message ?? 'Firestore error');
    } catch (e) {
      throw LanguagesFetchException(e.toString());
    }
  }
}
