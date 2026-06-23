import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/language.dart';
import '../domain/language_repository.dart';
import '../domain/languages_result.dart';

class LanguageRepositoryImpl implements LanguageRepository {
  LanguageRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<LanguagesResult> fetchAvailableLanguages() async {
    try {
      final snapshot = await _firestore
          .collection('languages')
          .where('enabled', isEqualTo: true)
          .orderBy('sort_order')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final languages = snapshot.docs
            .map((doc) => Language.fromFirestore(doc.data()))
            .toList();
        return LanguagesResult(languages: languages);
      }

      // Snapshot vacío. Una query Firestore sin red y sin caché NO lanza:
      // resuelve a un snapshot vacío con isFromCache=true. Hay que distinguirlo
      // de una colección remota legítimamente vacía (respuesta del servidor):
      //  - vacío DESDE CACHÉ → no pudimos contactar el servidor → fallback (retry).
      //  - vacío DESDE SERVIDOR → despliegue inicial real → defaults sin retry.
      if (snapshot.metadata.isFromCache) {
        _logFallback('empty query from cache (offline)');
        return const LanguagesResult(
            languages: Language.defaults, isFallback: true);
      }
      return const LanguagesResult(languages: Language.defaults);
    } on FirebaseException catch (e) {
      // Fallo de red/permiso al leer: NO lanzar. El onboarding no puede
      // quedarse sin idiomas, así que devolvemos los básicos en memoria y
      // marcamos isFallback para que la UI ofrezca "Reintentar".
      _logFallback(e.message ?? e.code);
      return const LanguagesResult(languages: Language.defaults, isFallback: true);
    } catch (e) {
      _logFallback(e.toString());
      return const LanguagesResult(languages: Language.defaults, isFallback: true);
    }
  }

  void _logFallback(String reason) {
    // El throw histórico (LanguagesFetchException) se sustituyó por un fallback
    // silencioso; dejamos rastro en debug para diagnóstico sin romper el flujo.
    assert(() {
      // ignore: avoid_print
      print('LanguageRepository: usando idiomas por defecto (fallback): $reason');
      return true;
    }());
  }
}
