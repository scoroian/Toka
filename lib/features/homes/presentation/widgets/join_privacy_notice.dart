import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Aviso de transparencia mostrado en el flujo de unión a un hogar (Hallazgo
/// #09): antes de confirmar la unión, informa de qué verán los demás miembros
/// (nombre, foto, estadísticas; teléfono solo si es visible). Widget puro: no
/// lee providers; recibe el estado por parámetro para ser testeable aislado.
class JoinPrivacyNotice extends StatelessWidget {
  const JoinPrivacyNotice({
    super.key,
    required this.phoneShared,
    this.onChangeVisibility,
  });

  /// El teléfono del usuario se compartirá con los miembros (tiene teléfono y
  /// `phoneVisibility == 'sameHomeMembers'`). Gobierna la línea del teléfono.
  final bool phoneShared;

  /// Si no es null, se muestra un enlace "Cambiar" que lo invoca (selector:
  /// navega a editar perfil). Si es null, se muestra una mención textual de
  /// dónde ajustarlo (onboarding: sin navegar fuera del flujo).
  final VoidCallback? onChangeVisibility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bodyStyle = textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Container(
      key: const Key('join_privacy_notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.join_privacy_notice_intro, style: bodyStyle),
                const SizedBox(height: 4),
                Text(
                  phoneShared
                      ? l10n.join_privacy_notice_phone_visible
                      : l10n.join_privacy_notice_phone_hidden,
                  style: bodyStyle?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (onChangeVisibility != null)
                  TextButton(
                    key: const Key('join_privacy_change_visibility'),
                    onPressed: onChangeVisibility,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(l10n.join_privacy_notice_change),
                  )
                else
                  Text(
                    l10n.join_privacy_notice_change_hint,
                    style: bodyStyle?.copyWith(fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
