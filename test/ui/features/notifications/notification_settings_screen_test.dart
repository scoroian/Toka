import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/notifications/application/notification_prefs_provider.dart';
import 'package:toka/features/notifications/application/notification_settings_view_model.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';
import 'package:toka/features/notifications/presentation/skins/notification_settings_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');

Widget _wrap({bool isPremium = false, bool systemAuthorized = true}) {
  final view = NotificationSettingsView(
    prefs: _prefs,
    isPremium: isPremium,
    systemAuthorized: systemAuthorized,
  );
  // ignore_for_file: prefer_const_constructors
  return ProviderScope(
    overrides: [
      notificationSettingsProvider('h1', 'u1')
          .overrideWith((_) => Stream.value(view)),
      notificationPrefsProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(_prefs)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreenV2(homeId: 'h1', uid: 'u1'),
    ),
  );
}

void main() {
  testWidgets(
      'Pantalla muestra toggle "Avisar al vencer" habilitado por defecto',
      (t) async {
    await t.pumpWidget(_wrap());
    await t.pumpAndSettle();
    expect(find.byKey(const Key('toggle_on_due')), findsOneWidget);
    final sw =
        t.widget<SwitchListTile>(find.byKey(const Key('toggle_on_due')));
    expect(sw.value, true);
  });

  testWidgets('Opciones Premium están deshabilitadas en plan Free', (t) async {
    await t.pumpWidget(_wrap());
    await t.pumpAndSettle();
    final sw = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_notify_before')));
    expect(sw.onChanged, isNull);
    final sw2 = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_daily_summary')));
    expect(sw2.onChanged, isNull);
  });

  testWidgets('Opciones Premium habilitadas cuando isPremium=true', (t) async {
    await t.pumpWidget(_wrap(isPremium: true));
    await t.pumpAndSettle();
    final sw = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_notify_before')));
    expect(sw.onChanged, isNotNull);
    final sw2 = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_daily_summary')));
    expect(sw2.onChanged, isNotNull);
  });

  testWidgets('Banner de sistema bloqueado aparece si systemAuthorized=false',
      (t) async {
    await t.pumpWidget(_wrap(systemAuthorized: false));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('system_blocked_banner')), findsOneWidget);
    final sw =
        t.widget<SwitchListTile>(find.byKey(const Key('toggle_on_due')));
    expect(sw.onChanged, isNull);
  });
}
