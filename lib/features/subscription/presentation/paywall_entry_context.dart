// lib/features/subscription/presentation/paywall_entry_context.dart
//
// Contexto con el que se abre el Paywall. Cambia la cabecera (título,
// subtítulo y CTA principal) pero NO los planes ni el flujo de compra.

library;

enum PaywallEntryContext {
  /// Usuario con plan free que aún no ha sido Premium (o purged). Copy
  /// clásico "Hazte Premium".
  fromFree,

  /// Usuario cuyo Premium ha expirado recientemente (expiredFree).
  /// Copy: "Reactivar Premium" + subtítulo con fecha de expiración.
  fromExpired,

  /// Usuario en la ventana de rescate (pago automático fallido, 3 días).
  /// Copy: "Renueva antes de perder tus capacidades" + días restantes.
  fromRescue,

  /// Usuario en la ventana de restauración (30 días tras downgrade).
  /// Copy: "Restaurar tu Premium" + días restantes.
  fromRestorable,
}
