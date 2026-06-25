import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/homes/application/homes_provider.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/homes/domain/homes_repository.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/members/domain/members_repository.dart';
import 'package:toka/features/settings/application/settings_view_model.dart';
import 'package:toka/features/settings/presentation/settings_screen.dart';
import 'package:toka/features/subscription/application/subscription_provider.dart';
import 'package:toka/features/subscription/application/toka_plus_enabled_provider.dart';
import 'package:toka/features/subscription/domain/subscription_state.dart';
import 'package:toka/l10n/app_localizations.dart';

/// Stub package_info_plus so it doesn't throw MissingPluginException in tests.
void _setupPackageInfoStub() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'Toka',
          'packageName': 'com.toka.app',
          'version': '1.0.0',
          'buildNumber': '1',
          'buildSignature': '',
          'installerStore': '',
        };
      }
      return null;
    },
  );
}

class _MockHomesRepository extends Mock implements HomesRepository {}
class _MockMembersRepository extends Mock implements MembersRepository {}

Member _makeMember({
  required String uid,
  String nickname = 'TestUser',
  MemberRole role = MemberRole.member,
  MemberStatus status = MemberStatus.active,
}) =>
    Member(
      uid: uid,
      homeId: 'home1',
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'none',
      role: role,
      status: status,
      joinedAt: DateTime(2024),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

class _FakeSettingsViewModel implements SettingsViewModel {
  const _FakeSettingsViewModel({required this.viewData});
  @override
  final SettingsViewData viewData;
}

Widget _wrap({SubscriptionState? subscription}) => ProviderScope(
      overrides: [
        if (subscription != null)
          subscriptionStateProvider.overrideWith((ref) => subscription),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const SettingsScreen(),
      ),
    );

Widget _wrapWithHome({
  required String homeId,
  required String uid,
  required _MockMembersRepository membersRepo,
  _MockHomesRepository? homesRepo,
  // Por defecto el usuario es el owner (ownerUid == uid). El Caso A (no-owner)
  // lo sobreescribe con el uid del propietario real.
  String? ownerUid,
}) {
  final vm = _FakeSettingsViewModel(
    viewData: SettingsViewData(
      isPremium: false,
      homeId: homeId,
      uid: uid,
      ownerUid: ownerUid ?? uid,
    ),
  );
  return ProviderScope(
    overrides: [
      settingsViewModelProvider.overrideWithValue(vm),
      membersRepositoryProvider.overrideWithValue(membersRepo),
      if (homesRepo != null)
        homesRepositoryProvider.overrideWithValue(homesRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: const SettingsScreen(),
    ),
  );
}

Widget _wrapPlus({required bool plusEnabled}) => ProviderScope(
      overrides: [
        tokaPlusEnabledProvider.overrideWithValue(plusEnabled),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: const SettingsScreen(),
      ),
    );

void main() {
  setUp(_setupPackageInfoStub);

  testWidgets('flag Plus ON: muestra entradas Toka Plus y Mis métricas',
      (tester) async {
    await tester.pumpWidget(_wrapPlus(plusEnabled: true));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('settings_plus_entry')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('settings_plus_entry')), findsOneWidget);
    expect(find.byKey(const Key('settings_metrics_entry')), findsOneWidget);
  });

  testWidgets('flag Plus OFF: oculta las entradas de Plus', (tester) async {
    await tester.pumpWidget(_wrapPlus(plusEnabled: false));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_plus_entry')), findsNothing);
    expect(find.byKey(const Key('settings_metrics_entry')), findsNothing);
  });

  testWidgets('SettingsScreen renderiza sección Cuenta', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_account')), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Suscripción', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('settings_section_subscription')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('settings_section_subscription')), findsOneWidget);
  });

  testWidgets('SettingsScreen muestra "Plan Premium" cuando hay Premium activo', (tester) async {
    await tester.pumpWidget(_wrap(
      subscription: SubscriptionState.active(
        plan: 'monthly',
        endsAt: DateTime(2027, 1, 1),
        autoRenew: true,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('subscription_status_label')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('subscription_status_label')), findsOneWidget);
    expect(find.text('Plan Premium'), findsOneWidget);
  });

  testWidgets('SettingsScreen muestra "Plan gratuito" cuando no hay Premium', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.byKey(const Key('subscription_status_label')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.byKey(const Key('subscription_status_label')), findsOneWidget);
    expect(find.text('Plan gratuito'), findsOneWidget);
  });

  testWidgets('SettingsScreen renderiza sección Acerca de', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    // Scroll to the bottom to reveal the "Acerca de" section.
    await tester.dragUntilVisible(
      find.byKey(const Key('settings_section_about')),
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings_section_about')), findsOneWidget);
  });

  testWidgets('golden: SettingsScreen', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen.png'),
    );
  });

  // ── Tests flujo owner leave home ─────────────────────────────────────────

  testWidgets('Caso A: no-owner muestra diálogo de confirmación genérico',
      (tester) async {
    final membersRepo = _MockMembersRepository();
    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(uid: 'user1', role: MemberRole.member),
      ]),
    );

    await tester.pumpWidget(_wrapWithHome(
      homeId: 'home1',
      uid: 'user1',
      ownerUid: 'owner1',
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    final leaveTile = find.text('Abandonar hogar');
    await tester.scrollUntilVisible(
      leaveTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // ensureVisible deja el tile completamente dentro del viewport: tras
    // scrollUntilVisible su centro puede quedar justo bajo el borde inferior y
    // el tap no impactaría el ListTile.
    await tester.ensureVisible(leaveTile);
    await tester.pumpAndSettle();
    await tester.tap(leaveTile);
    await tester.pumpAndSettle();

    expect(find.text('¿Abandonar hogar?'), findsOneWidget);
    expect(find.text('Transferir propiedad del hogar'), findsNothing);
  });

  testWidgets('Caso B: owner con activos muestra TransferOwnershipDialog',
      (tester) async {
    final membersRepo = _MockMembersRepository();
    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(uid: 'active1', nickname: 'Alice', role: MemberRole.member),
      ]),
    );

    await tester.pumpWidget(_wrapWithHome(
      homeId: 'home1',
      uid: 'owner1',
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    final leaveTile = find.text('Abandonar hogar');
    await tester.scrollUntilVisible(
      leaveTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // ensureVisible deja el tile completamente dentro del viewport: tras
    // scrollUntilVisible su centro puede quedar justo bajo el borde inferior y
    // el tap no impactaría el ListTile.
    await tester.ensureVisible(leaveTile);
    await tester.pumpAndSettle();
    await tester.tap(leaveTile);
    await tester.pumpAndSettle();

    expect(find.text('Transferir propiedad del hogar'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.byKey(const Key('transfer_confirm_btn')), findsOneWidget);
  });

  testWidgets('Caso C: owner único muestra diálogo eliminar hogar',
      (tester) async {
    final membersRepo = _MockMembersRepository();
    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
      ]),
    );

    await tester.pumpWidget(_wrapWithHome(
      homeId: 'home1',
      uid: 'owner1',
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    final leaveTile = find.text('Abandonar hogar');
    await tester.scrollUntilVisible(
      leaveTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // ensureVisible deja el tile completamente dentro del viewport: tras
    // scrollUntilVisible su centro puede quedar justo bajo el borde inferior y
    // el tap no impactaría el ListTile.
    await tester.ensureVisible(leaveTile);
    await tester.pumpAndSettle();
    await tester.tap(leaveTile);
    await tester.pumpAndSettle();

    expect(find.text('Eliminar hogar'), findsOneWidget);
    expect(find.byKey(const Key('delete_home_confirm_btn')), findsOneWidget);
  });

  testWidgets('Caso D: owner con solo congelados muestra FrozenTransferDialog',
      (tester) async {
    final membersRepo = _MockMembersRepository();
    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        _makeMember(uid: 'owner1', role: MemberRole.owner),
        _makeMember(
          uid: 'frozen1',
          nickname: 'Bob',
          role: MemberRole.member,
          status: MemberStatus.frozen,
        ),
      ]),
    );

    await tester.pumpWidget(_wrapWithHome(
      homeId: 'home1',
      uid: 'owner1',
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    final leaveTile = find.text('Abandonar hogar');
    await tester.scrollUntilVisible(
      leaveTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // ensureVisible deja el tile completamente dentro del viewport: tras
    // scrollUntilVisible su centro puede quedar justo bajo el borde inferior y
    // el tap no impactaría el ListTile.
    await tester.ensureVisible(leaveTile);
    await tester.pumpAndSettle();
    await tester.tap(leaveTile);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('frozen_delete_btn')), findsOneWidget);
    expect(find.byKey(const Key('frozen_transfer_btn')), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
  });

  // Regresión 🟠-2 (QA 2026-06-19): un ex-owner re-unido como admin puede
  // tener la caché local de miembros diciendo aún que es owner. El flujo de
  // "Abandonar hogar" debe clasificarse por home.ownerUid (vía el view model),
  // NO por la lista de miembros, así que NO debe ofrecer "Transferir
  // propiedad" cuando ya no es el propietario real.
  testWidgets(
      'Regresión: members stale lo marca owner pero ownerUid != uid → flujo no-owner',
      (tester) async {
    final membersRepo = _MockMembersRepository();
    when(() => membersRepo.watchHomeMembers('home1')).thenAnswer(
      (_) => Stream.value([
        // Caché stale: el usuario aún aparece como owner…
        _makeMember(uid: 'user1', role: MemberRole.owner),
        _makeMember(uid: 'realowner', nickname: 'Real', role: MemberRole.member),
      ]),
    );

    await tester.pumpWidget(_wrapWithHome(
      homeId: 'home1',
      uid: 'user1',
      ownerUid: 'realowner', // …pero el propietario real es otro
      membersRepo: membersRepo,
    ));
    await tester.pumpAndSettle();

    final leaveTile = find.text('Abandonar hogar');
    await tester.scrollUntilVisible(
      leaveTile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(leaveTile);
    await tester.pumpAndSettle();
    await tester.tap(leaveTile);
    await tester.pumpAndSettle();

    expect(find.text('¿Abandonar hogar?'), findsOneWidget);
    expect(find.text('Transferir propiedad del hogar'), findsNothing);
  });
}
