// lib/features/tasks/presentation/widgets/unfreeze_blocked_dialog.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/routes.dart';
import '../../../../l10n/app_localizations.dart';

/// Diálogo mostrado cuando un usuario Free intenta descongelar una tarea pero
/// el hogar ya está en el tope de tareas activas del plan Free.
///
/// Ofrece dos acciones:
/// - "Entendido" (secundaria): cierra el diálogo para que el usuario pueda
///    congelar otra tarea manualmente y volver a intentarlo.
/// - "Hazte Premium" (primaria): navega al paywall.
Future<void> showUnfreezeBlockedDialog(
  BuildContext context, {
  required int current,
  required int limit,
}) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => AlertDialog(
      key: const Key('unfreeze_blocked_dialog'),
      title: Text(l10n.free_unfreeze_blocked_title),
      content: Text(l10n.free_unfreeze_blocked_body(current, limit)),
      actions: [
        TextButton(
          key: const Key('unfreeze_blocked_dialog_dismiss'),
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: Text(l10n.free_unfreeze_blocked_understood),
        ),
        ElevatedButton(
          key: const Key('unfreeze_blocked_dialog_premium'),
          onPressed: () {
            Navigator.of(dialogCtx).pop();
            context.push(AppRoutes.paywall);
          },
          child: Text(l10n.free_go_premium_cta),
        ),
      ],
    ),
  );
}
