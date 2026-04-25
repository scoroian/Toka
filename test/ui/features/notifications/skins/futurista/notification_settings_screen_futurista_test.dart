// test/ui/features/notifications/skins/futurista/notification_settings_screen_futurista_test.dart
//
// Verifica el wrapper `NotificationSettingsScreen`:
//  - renderiza la variante v2 (`NotificationSettingsScreenV2`) por defecto.
//  - renderiza la variante futurista cuando `skinModeProvider` está overrideado
//    a `AppSkin.futurista`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/notifications/application/notification_prefs_provider.dart';
import 'package:toka/features/notifications/application/notification_settings_view_model.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';
import 'package:toka/features/notifications/presentation/skins/futurista/notification_settings_screen_futurista.dart';
import 'package:toka/features/notifications/presentation/skins/notification_settings_screen.dart';
import 'package:toka/features/notifications/presentation/skins/notification_settings_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

const _prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');

class _SkinModeStub extends SkinMode {
  _SkinModeStub(this._initial);
  final AppSkin _initial;
  @override
  AppSkin build() => _initial;
}

Widget _harness({required AppSkin skin}) {
  const view = NotificationSettingsView(
    prefs: _prefs,
    isPremium: true,
    systemAuthorized: true,
  );
  return ProviderScope(
    overrides: [
      skinModeProvider.overrideWith(() => _SkinModeStub(skin)),
      notificationSettingsProvider('h1', 'u1')
          .overrideWith((_) => Stream.value(view)),
      notificationPrefsProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(_prefs)),
    ],
    child: const MaterialApp(
      locale: Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: NotificationSettingsScreen(homeId: 'h1', uid: 'u1'),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (t) async {
    await t.pumpWidget(_harness(skin: AppSkin.v2));
    await t.pumpAndSettle();

    expect(find.byType(NotificationSettingsScreenV2), findsOneWidget);
    expect(find.byType(NotificationSettingsScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista', (t) async {
    await t.pumpWidget(_harness(skin: AppSkin.futurista));
    await t.pumpAndSettle();

    expect(find.byType(NotificationSettingsScreenFuturista), findsOneWidget);
    expect(find.byType(NotificationSettingsScreenV2), findsNothing);
  });
}
