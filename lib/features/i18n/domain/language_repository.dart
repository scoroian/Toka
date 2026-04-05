import 'language.dart';

abstract interface class LanguageRepository {
  Future<List<Language>> fetchAvailableLanguages();
}
