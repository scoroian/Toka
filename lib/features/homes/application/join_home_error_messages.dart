import '../../../l10n/app_localizations.dart';
import 'join_home_error.dart';

/// El ÚNICO mapa motivo → texto localizado de los errores de unión a un hogar.
/// Selector multi-hogar y onboarding lo comparten, así que la paridad de
/// mensajes ("mismo motivo, mismo mensaje") queda garantizada por construcción
/// (Hallazgo #04, lote UX 2026-06-25).
String joinHomeErrorMessage(JoinHomeError reason, AppLocalizations l10n) {
  switch (reason) {
    case JoinHomeError.invalidCode:
      return l10n.join_error_invalid_code;
    case JoinHomeError.expiredCode:
      return l10n.join_error_expired_code;
    case JoinHomeError.homeFull:
      return l10n.join_error_home_full;
    case JoinHomeError.noAccountSlots:
      return l10n.join_error_no_account_slots;
    case JoinHomeError.tooManyAttempts:
      return l10n.join_error_too_many_attempts;
    case JoinHomeError.permissionDenied:
      return l10n.join_error_permission_denied;
    case JoinHomeError.network:
      return l10n.join_error_network;
    case JoinHomeError.unexpected:
      return l10n.join_error_generic;
  }
}
