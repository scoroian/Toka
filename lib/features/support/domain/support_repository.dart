import 'home_diagnostics.dart';

/// Acceso al diagnóstico de soporte (Hallazgo #17). La implementación llama a la
/// callable backend `supportDiagnoseHome` (App Check + claim `support`).
abstract class SupportRepository {
  /// Devuelve el diagnóstico REDACTADO del hogar indicado.
  /// Lanza [SupportException] con un código estable en caso de error.
  Future<HomeDiagnostics> diagnoseHome(String homeId);
}

/// Error de dominio para la feature de soporte. `code` es estable y mapeable a
/// un mensaje i18n; deriva del code de FirebaseFunctionsException.
class SupportException implements Exception {
  const SupportException(this.code);
  final String code;
  @override
  String toString() => 'SupportException($code)';
}
