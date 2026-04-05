import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/language.dart';
import '../domain/language_repository.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  LanguageRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<List<Language>> fetchAvailableLanguages() async {
    try {
      final snapshot = await _firestore
          .collection('languages')
          .where('enabled', isEqualTo: true)
          .orderBy('sort_order')
          .get();
      return snapshot.docs
          .map((doc) => Language.fromFirestore(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw LanguagesFetchException(e.message ?? 'Firestore error');
    } catch (e) {
      throw LanguagesFetchException(e.toString());
    }
  }
}
