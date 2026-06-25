import 'plus_entitlement.dart';

/// Acceso de SOLO LECTURA al entitlement individual "Toka Plus" del usuario.
///
/// El doc `users/{uid}/entitlements/plus` lo escribe únicamente el backend; el
/// cliente solo observa cambios para reflejar el desbloqueo/bloqueo en vivo.
abstract class PlusRepository {
  /// Stream del entitlement del usuario [uid]. Emite `null` si el doc no existe
  /// (usuario sin Plus).
  Stream<PlusEntitlement?> watch(String uid);
}
