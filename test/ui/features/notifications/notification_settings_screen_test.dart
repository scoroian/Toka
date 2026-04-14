import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/notifications/application/notification_prefs_provider.dart';
import 'package:toka/features/notifications/application/notification_settings_view_model.dart';
import 'package:toka/features/notifications/domain/notification_preferences.dart';
import 'package:toka/features/notifications/presentation/notification_settings_screen.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockNotifVM extends Mock implements NotificationSettingsViewModel {}

const _prefs = NotificationPreferences(homeId: 'h1', uid: 'u1');

_MockNotifVM _defaultMock({bool isPremium = false}) {
  final m = _MockNotifVM();
  when(() => m.isLoaded).thenReturn(true);
  when(() => m.isPremium).thenReturn(isPremium);
  when(() => m.prefs).thenReturn(_prefs);
  when(() => m.updatePrefs(any())).thenAnswer((_) async {});
  return m;
}

Widget _wrap(Widget child, {_MockNotifVM? vm, bool isPremium = false}) {
  final mock = vm ?? _defaultMock(isPremium: isPremium);
  return ProviderScope(
    overrides: [
      notificationSettingsViewModelProvider('h1', 'u1')
          .overrideWithValue(mock),
      // Keep data overrides so the notifier can build when the screen reads it
      notificationPrefsProvider(homeId: 'h1', uid: 'u1')
          .overrideWith((_) => Stream.value(_prefs)),
      subscriptionStateProvider
          .overrideWith((_) => const SubscriptionState.free()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const NotificationPreferences(homeId: '', uid: ''));
  });

  testWidgets(
      'Pantalla muestra toggle "Avisar al vencer" habilitado por defecto',
      (t) async {
    await t.pumpWidget(
        _wrap(const NotificationSettingsScreen(homeId: 'h1', uid: 'u1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('toggle_on_due')), findsOneWidget);
    final sw =
        t.widget<SwitchListTile>(find.byKey(const Key('toggle_on_due')));
    expect(sw.value, true);
  });

  testWidgets('Opciones Premium están deshabilitadas en plan Free', (t) async {
    await t.pumpWidget(
        _wrap(const NotificationSettingsScreen(homeId: 'h1', uid: 'u1')));
    await t.pumpAndSettle();
    final sw = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_notify_before')));
    expect(sw.onChanged, isNull);
    final sw2 = t.widget<SwitchListTile>(
        find.byKey(const Key('toggle_daily_summary')));
    expect(sw2.onChanged, isNull);
  });
}
