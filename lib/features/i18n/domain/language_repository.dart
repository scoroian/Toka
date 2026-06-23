import 'languages_result.dart';

abstract interface class LanguageRepository {
  /// Devuelve los idiomas disponibles. Nunca lanza por fallo de red: ante un
  /// error de lectura devuelve los idiomas básicos con [LanguagesResult.isFallback]
  /// en `true` para que la UI pueda ofrecer "Reintentar".
  Future<LanguagesResult> fetchAvailableLanguages();
}
