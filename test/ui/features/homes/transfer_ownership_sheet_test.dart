import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/presentation/widgets/transfer_ownership_sheet.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

Member _member({
  required String uid,
  required String nickname,
  MemberRole role = MemberRole.member,
}) =>
    Member(
      uid: uid,
      homeId: 'h1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2026, 1, 1),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0,
    );

Widget _harness(_MockMembersRepository repo) => ProviderScope(
      overrides: [
        membersRepositoryProvider.overrideWithValue(repo),
        adBannerConfigProvider
            .overrideWithValue(const AdBannerConfig(show: false, unitId: '')),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () =>
                    showTransferOwnershipSheet(context, homeId: 'h1'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  late _MockMembersRepository repo;

  setUp(() {
    repo = _MockMembersRepository();
    when(() => repo.watchHomeMembers('h1')).thenAnswer(
      (_) => Stream.value([
        _member(uid: 'owner', nickname: 'Dueño', role: MemberRole.owner),
        _member(uid: 'u2', nickname: 'Beto'),
      ]),
    );
  });

  // Regresión bug #12 (QA 2026-06-16): al transferir siendo el pagador del
  // Premium activo, el backend rechaza pero la UI no avisaba (falso éxito por
  // AsyncValue.guard). Ahora debe mostrar el SnackBar específico.
  testWidgets('payer-lock en transferencia muestra SnackBar específico',
      (tester) async {
    when(() => repo.transferOwnership('h1', 'u2'))
        .thenThrow(const PayerLockedException());

    await tester.pumpWidget(_harness(repo));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    // El owner no debe aparecer como candidato; sí el otro miembro.
    expect(find.byKey(const Key('transfer_candidate_u2')), findsOneWidget);
    expect(find.byKey(const Key('transfer_candidate_owner')), findsNothing);

    await tester.tap(find.byKey(const Key('transfer_candidate_u2')));
    await tester.pumpAndSettle();

    // Diálogo de confirmación → confirmar.
    await tester.tap(find.byKey(const Key('btn_transfer_confirm')));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    expect(find.text(l10n.homes_transfer_error_payer_locked), findsOneWidget);
    // No debe mostrar un falso mensaje de éxito.
    expect(find.text(l10n.homes_transfer_success('Beto')), findsNothing);
    // El sheet debe haberse cerrado para que el SnackBar quede visible (si el
    // sheet siguiera abierto taparía el aviso — verificado en dispositivo).
    expect(find.byKey(const Key('transfer_candidate_u2')), findsNothing);
  });

  testWidgets('transferencia exitosa muestra SnackBar de éxito',
      (tester) async {
    when(() => repo.transferOwnership('h1', 'u2')).thenAnswer((_) async {});

    await tester.pumpWidget(_harness(repo));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('transfer_candidate_u2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('btn_transfer_confirm')));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('es'));
    expect(find.text(l10n.homes_transfer_success('Beto')), findsOneWidget);
    verify(() => repo.transferOwnership('h1', 'u2')).called(1);
  });
}
