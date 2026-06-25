import 'package:flutter/material.dart';

import '../../../../core/constants/free_limits.dart';
import '../../../../l10n/app_localizations.dart';

/// Diálogo informativo de **Toka Business**, mostrado al intentar crecer por
/// encima del tope absoluto ([kAbsoluteMaxMembers]). El producto B2B está fuera
/// de alcance: es solo un mensaje (un único botón para descartar), sin flujo de
/// compra ni enlace externo.
Future<void> showTokaBusinessDialog(
  BuildContext context, {
  int max = kAbsoluteMaxMembers,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => AlertDialog(
      key: const Key('toka_business_dialog'),
      title: Text(l10n.toka_business_title),
      content: Text(l10n.toka_business_body(max)),
      actions: [
        FilledButton(
          key: const Key('toka_business_dialog_dismiss'),
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(l10n.toka_business_dismiss),
        ),
      ],
    ),
  );
}
