import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'notification_rationale_screen_v2.dart';

class NotificationRationaleScreen extends StatelessWidget {
  const NotificationRationaleScreen({super.key});

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => const NotificationRationaleScreenV2(),
      );
}
