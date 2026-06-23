// Hallazgo #12 — el flujo de invitar no deja al usuario sin feedback.
//
// La rama "Invitar por email" se retiró (llamaba a una callable inexistente y
// el botón cerraba el sheet en silencio). Queda solo código/QR, que SÍ da
// feedback: spinner mientras genera y un error visible si la generación falla.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/members/presentation/widgets/invite_member_sheet.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

Widget _harness(_MockMembersRepository repo) => ProviderScope(
      overrides: [
        membersRepositoryProvider.overrideWithValue(repo),
        adBannerConfigProvider
            .overrideWith((ref) => const AdBannerConfig(show: false, unitId: '')),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: const Scaffold(body: InviteMemberSheet(homeId: 'h1')),
      ),
    );

void main() {
  testWidgets('generar código que falla muestra el error (no fallo silencioso)',
      (tester) async {
    final repo = _MockMembersRepository();
    when(() => repo.generateInviteCode('h1')).thenThrow(Exception('boom'));

    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    // No queda ningún botón muerto de email.
    expect(find.byKey(const Key('btn_invite_email')), findsNothing);
    expect(find.byKey(const Key('btn_send_invite')), findsNothing);
    expect(find.byKey(const Key('btn_share_code')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn_share_code')));
    await tester.pumpAndSettle();

    // El error es visible: el usuario recibe feedback en vez de un cierre mudo.
    expect(find.byKey(const Key('invite_code_error')), findsOneWidget);
    verify(() => repo.generateInviteCode('h1')).called(1);
  });

  testWidgets('generar código con éxito muestra el código', (tester) async {
    final repo = _MockMembersRepository();
    final expiresAt = DateTime.now().add(const Duration(days: 7));
    when(() => repo.generateInviteCode('h1'))
        .thenAnswer((_) async => (code: 'ABC234', expiresAt: expiresAt));

    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('btn_share_code')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invite_code_text')), findsOneWidget);
    expect(find.text('ABC234'), findsOneWidget);
  });
}
