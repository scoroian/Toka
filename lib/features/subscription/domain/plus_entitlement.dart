import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plus_entitlement.freezed.dart';

/// Vista de cliente del entitlement INDIVIDUAL "Toka Plus".
///
/// Espeja el doc privado `users/{uid}/entitlements/plus` que escribe SOLO el
/// backend (verificación de recibos / reconciliación con stores). El cliente
/// únicamente lee (reglas: `allow read: if isUser(uid)`), nunca escribe.
///
/// `active` es la verdad cruda de la store; la activación EFECTIVA (que decide
/// el gating) la calcula [plusActiveProvider] combinando este `active`, el flag
/// de Remote Config `toka_plus_enabled` y `endsAt` (defensa en profundidad,
/// espejo de `isPlusEffectivelyActive` del backend).
@freezed
class PlusEntitlement with _$PlusEntitlement {
  const factory PlusEntitlement({
    required String status,
    required bool active,
    String? cycle,
    DateTime? startsAt,
    DateTime? endsAt,
    @Default(false) bool autoRenewEnabled,
    String? productId,
  }) = _PlusEntitlement;

  const PlusEntitlement._();

  /// Construye desde el doc Firestore. Tolerante a campos ausentes (fail-safe a
  /// "sin Plus"): `status=''`, `active=false`, fechas nulas.
  factory PlusEntitlement.fromMap(Map<String, dynamic> data) {
    DateTime? ts(dynamic v) => v is Timestamp ? v.toDate() : null;
    return PlusEntitlement(
      status: (data['status'] as String?) ?? '',
      active: data['active'] == true,
      cycle: data['cycle'] as String?,
      startsAt: ts(data['startsAt']),
      endsAt: ts(data['endsAt']),
      autoRenewEnabled: data['autoRenewEnabled'] == true,
      productId: data['productId'] as String?,
    );
  }

  /// El ciclo es anual si el productId/cycle lo indica.
  bool get isAnnual => cycle == 'annual';
}
