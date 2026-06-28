import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/presentation/widgets/join_privacy_notice.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('muestra siempre el texto base (nombre/foto/estadísticas)',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_privacy_notice')), findsOneWidget);
    expect(
      find.text(
          'Al unirte, los miembros del hogar verán tu nombre, tu foto y tus estadísticas de tareas.'),
      findsOneWidget,
    );
  });

  testWidgets('phoneShared=true → promete teléfono visible; no dice oculto',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: true)));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsOneWidget);
    expect(find.text('Tu teléfono permanece oculto.'), findsNothing);
  });

  testWidgets('phoneShared=false → dice oculto; NO promete mostrarlo',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.text('Tu teléfono permanece oculto.'), findsOneWidget);
    expect(find.text('Tu teléfono también será visible para ellos.'),
        findsNothing);
  });

  testWidgets('con onChangeVisibility → muestra enlace "Cambiar" y lo invoca',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(
      JoinPrivacyNotice(phoneShared: false, onChangeVisibility: () => taps++),
    ));
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('join_privacy_change_visibility'));
    expect(link, findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    // La mención textual NO aparece cuando hay enlace.
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsNothing);

    await tester.tap(link);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('sin onChangeVisibility → mención textual, sin enlace',
      (tester) async {
    await tester.pumpWidget(_wrap(const JoinPrivacyNotice(phoneShared: false)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('join_privacy_change_visibility')), findsNothing);
    expect(
        find.text('Puedes ajustar la visibilidad de tu teléfono en tu perfil.'),
        findsOneWidget);
  });
}
