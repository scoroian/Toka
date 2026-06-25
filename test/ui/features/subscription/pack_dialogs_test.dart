import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/member_pack_catalog.dart';
import 'package:toka/features/subscription/presentation/widgets/pack_cancel_dialog.dart';
import 'package:toka/features/subscription/presentation/widgets/toka_business_dialog.dart';
import 'package:toka/l10n/app_localizations.dart';

Widget _host({
  required void Function(BuildContext) onPressed,
  Locale locale = const Locale('es'),
}) =>
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
      locale: locale,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              key: const Key('open'),
              onPressed: () => onPressed(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

void main() {
  group('showPackCancelFreezeDialog', () {
    testWidgets('muestra el aviso de congelación con el nº de excedentes',
        (tester) async {
      await tester.pumpWidget(_host(onPressed: (context) {
        showPackCancelFreezeDialog(
          context,
          pack: MemberPack.plus10,
          newMax: 15,
          activeMembers: 18,
          endsAt: DateTime(2026, 7, 1),
        );
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pack_cancel_dialog')), findsOneWidget);
      // 18 activos - 15 tope = 3 congelados.
      expect(find.textContaining('3'), findsWidgets);
      // Fecha de fin del pack.
      expect(find.textContaining('01/07/2026'), findsOneWidget);
    });

    testWidgets('sin excedentes muestra el copy sin congelación', (tester) async {
      await tester.pumpWidget(_host(onPressed: (context) {
        showPackCancelFreezeDialog(
          context,
          pack: MemberPack.plus5,
          newMax: 10,
          activeMembers: 8,
        );
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final l10n = await AppLocalizations.delegate.load(const Locale('es'));
      expect(find.text(l10n.pack_cancel_no_freeze(10)), findsOneWidget);
    });

    testWidgets('confirmar devuelve true', (tester) async {
      bool? result;
      await tester.pumpWidget(_host(onPressed: (context) async {
        result = await showPackCancelFreezeDialog(
          context,
          pack: MemberPack.plus5,
          newMax: 10,
          activeMembers: 13,
        );
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pack_cancel_dialog_confirm')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byKey(const Key('pack_cancel_dialog')), findsNothing);
    });

    testWidgets('descartar devuelve false', (tester) async {
      bool? result;
      await tester.pumpWidget(_host(onPressed: (context) async {
        result = await showPackCancelFreezeDialog(
          context,
          pack: MemberPack.plus5,
          newMax: 10,
          activeMembers: 13,
        );
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pack_cancel_dialog_dismiss')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byKey(const Key('pack_cancel_dialog')), findsNothing);
    });

    testWidgets('en inglés los textos vienen de ARB', (tester) async {
      await tester.pumpWidget(_host(
        locale: const Locale('en'),
        onPressed: (context) {
          showPackCancelFreezeDialog(context,
              pack: MemberPack.plus10, newMax: 15, activeMembers: 18);
        },
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.text('Cancel pack'), findsOneWidget);
      expect(find.text('Keep pack'), findsOneWidget);
    });

    testWidgets('en rumano renderiza sin overflow', (tester) async {
      await tester.pumpWidget(_host(
        locale: const Locale('ro'),
        onPressed: (context) {
          showPackCancelFreezeDialog(context,
              pack: MemberPack.plus10, newMax: 15, activeMembers: 18);
        },
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('pack_cancel_dialog')), findsOneWidget);
    });

    testWidgets('golden: diálogo de congelación (es)', (tester) async {
      await tester.pumpWidget(_host(onPressed: (context) {
        showPackCancelFreezeDialog(
          context,
          pack: MemberPack.plus10,
          newMax: 15,
          activeMembers: 18,
          endsAt: DateTime(2026, 7, 1),
        );
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('goldens/pack_cancel_dialog.png'),
      );
    });
  });

  group('showTokaBusinessDialog', () {
    testWidgets('muestra el mensaje informativo y se descarta', (tester) async {
      await tester.pumpWidget(_host(onPressed: (context) {
        showTokaBusinessDialog(context);
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('toka_business_dialog')), findsOneWidget);
      expect(find.text('Toka Business'), findsOneWidget);
      expect(find.textContaining('25'), findsWidgets);

      await tester.tap(find.byKey(const Key('toka_business_dialog_dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('toka_business_dialog')), findsNothing);
    });

    testWidgets('en inglés viene de ARB', (tester) async {
      await tester.pumpWidget(_host(
        locale: const Locale('en'),
        onPressed: (context) => showTokaBusinessDialog(context),
      ));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      expect(find.text('Got it'), findsOneWidget);
    });

    testWidgets('golden: diálogo Toka Business (es)', (tester) async {
      await tester.pumpWidget(_host(onPressed: (context) {
        showTokaBusinessDialog(context);
      }));
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('goldens/toka_business_dialog.png'),
      );
    });
  });
}
