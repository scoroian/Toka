import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  testWidgets('renderiza una card por AppSkin (solo Clásico por ahora)',
      (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.text('Clásico'), findsOneWidget);
    // La skin Futurista se eliminó: no debe aparecer su card.
    expect(find.text('Futurista'), findsNothing);
  });

  testWidgets('la card activa (Clásico) muestra el check', (tester) async {
    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });
}
