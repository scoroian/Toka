import 'language.dart';

/// Resultado de cargar la lista de idiomas disponibles.
///
/// [isFallback] es `true` cuando la lectura remota falló (p. ej. sin red) y se
/// devolvieron los idiomas básicos en memoria ([Language.defaults]). La UI lo
/// usa para ofrecer "Reintentar" y avisar de que está en modo sin conexión.
/// Una colección vacía (lectura correcta) NO es fallback: es el caso normal de
/// despliegue inicial.
class LanguagesResult {
  const LanguagesResult({
    required this.languages,
    this.isFallback = false,
  });

  final List<Language> languages;
  final bool isFallback;

  @override
  bool operator ==(Object other) =>
      other is LanguagesResult &&
      other.isFallback == isFallback &&
      _listEquals(other.languages, languages);

  @override
  int get hashCode => Object.hash(isFallback, Object.hashAll(languages));

  static bool _listEquals(List<Language> a, List<Language> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
