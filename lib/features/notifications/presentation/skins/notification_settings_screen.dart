// lib/features/notifications/presentation/skins/notification_settings_screen.dart
//
// Wrapper "skin-aware" que renderiza `NotificationSettingsScreenV2` (única
// skin activa) según el `SkinMode` persistido. Consume
// `notificationSettingsProvider` y `notificationSettingsActionsProvider`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
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
      );
}
