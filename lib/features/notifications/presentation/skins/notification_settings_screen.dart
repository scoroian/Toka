// lib/features/notifications/presentation/skins/notification_settings_screen.dart
//
// Wrapper que elige entre `NotificationSettingsScreenV2` y
// `NotificationSettingsScreenFuturista` según el `SkinMode` persistido.
// Ambas variantes consumen los mismos providers (`notificationSettingsProvider`
// y `notificationSettingsActionsProvider`), por lo que el cambio es solo
// visual.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'futurista/notification_settings_screen_futurista.dart';
import 'notification_settings_screen_v2.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({
    super.key,
    required this.homeId,
    required this.uid,
  });

  final String homeId;
  final String uid;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => NotificationSettingsScreenV2(homeId: homeId, uid: uid),
        futurista: (_) =>
            NotificationSettingsScreenFuturista(homeId: homeId, uid: uid),
      );
}
