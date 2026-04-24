import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/settings/presentation/widgets/appearance_picker.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _harness() {
  return const ProviderScope(
    child: MaterialApp(
      locale: Locale('es'),
      supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: AppearancePicker()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders a card per AppSkin value', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Clásico'), findsOneWidget);
    expect(find.text('Futurista'), findsOneWidget);
  });

  testWidgets('tap on Futurista updates skinModeProvider', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Futurista'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(AppearancePicker)),
    );
    expect(container.read(skinModeProvider), AppSkin.futurista);
  });

  testWidgets('selected card shows check icon', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    // por defecto v2 está seleccionado → debería haber un check
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    // al cambiar a futurista, solo hay un check (ahora en la card futurista)
    await tester.tap(find.text('Futurista'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
