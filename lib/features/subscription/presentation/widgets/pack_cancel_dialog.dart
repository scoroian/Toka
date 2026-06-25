import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/member_pack_catalog.dart';
import '../pack_display.dart';

/// Diálogo de **aviso de congelación** antes de cancelar un pack de miembros.
///
/// Reutiliza el patrón del flujo de downgrade: avisa, ANTES de confirmar, de que
/// al terminar el pack el tope baja a [newMax] y los miembros excedentes (los
/// más recientes por encima del nuevo tope) se congelarán (recuperables). El
/// freeze real lo aplica el backend cuando la store reporta la cancelación; aquí
/// solo se previsualiza el impacto y se confirma la intención.
///
/// Devuelve `true` si el usuario confirma la cancelación (el llamador abre
/// entonces la gestión de suscripciones de la store), `false` si la descarta.
Future<bool> showPackCancelFreezeDialog(
  BuildContext context, {
  required MemberPack pack,
  required int newMax,
  required int activeMembers,
  DateTime? endsAt,
}) async {
  final l10n = AppLocalizations.of(context);
  final frozenCount = (activeMembers - newMax).clamp(0, activeMembers);

  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => AlertDialog(
      key: const Key('pack_cancel_dialog'),
      title: Text(l10n.pack_cancel_title(packDisplayName(l10n, pack))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (endsAt != null) ...[
            Text(l10n.pack_cancel_active_until(_formatDate(endsAt))),
            const SizedBox(height: 8),
          ],
          Text(
            frozenCount > 0
                ? l10n.pack_cancel_freeze_warning(frozenCount, newMax)
                : l10n.pack_cancel_no_freeze(newMax),
            key: const Key('pack_cancel_dialog_freeze_text'),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('pack_cancel_dialog_dismiss'),
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: Text(l10n.pack_cancel_dismiss),
        ),
        FilledButton(
          key: const Key('pack_cancel_dialog_confirm'),
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: Text(l10n.pack_cancel_confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}
