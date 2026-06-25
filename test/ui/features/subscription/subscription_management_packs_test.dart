import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/subscription/application/home_tiers_provider.dart';
import 'package:toka/features/subscription/application/member_packs_enabled_provider.dart';
import 'package:toka/features/subscription/application/paywall_provider.dart';
import 'package:toka/features/subscription/application/subscription_dashboard_provider.dart';
import 'package:toka/features/subscription/domain/purchase_result.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/subscription/presentation/skins/subscription_management_screen_v2.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

const _payer = AuthUser(
  uid: 'payer1',
  email: 'p@test.com',
  displayName: 'P',
  photoUrl: null,
  emailVerified: true,
  providers: [],
);

class _FakePaywall extends Paywall {
  @override
  AsyncValue<PurchaseResult?> build() {
    ref.onDispose(() {});
    return const AsyncValue.data(null);
  }

  @override
  Future<void> startPurchase(
      {required String homeId, required String productId}) async {}
  @override
  Future<void> restorePremium({required String homeId}) async {}
}

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(_payer);
}

List<Member> _members(int n) => List.generate(
      n,
      (i) => Member(
        uid: 'm$i',
        homeId: 'h1',
        nickname: 'M$i',
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: 'hidden',
        role: i == 0 ? MemberRole.owner : MemberRole.member,
        status: MemberStatus.active,
        joinedAt: DateTime(2026, 1, i + 1),
        tasksCompleted: 0,
        passedCount: 0,
        complianceRate: 1.0,
        currentStreak: 0,
        averageScore: 0.0,
      ),
    );

SubscriptionDashboard _dashboard({
  String tier = 'grupo',
  int maxMembers = 20,
  MemberPacks? packs,
}) =>
    SubscriptionDashboard(
      homeId: 'h1',
      status: HomePremiumStatus.active,
      plan: 'annual',
      endsAt: DateTime(2027),
      restoreUntil: null,
      autoRenew: true,
      currentPayerUid: 'payer1',
      planCounters: PlanCounters.empty(),
      tier: tier,
      maxMembers: maxMembers,
      memberPacks: packs,
    );

List<Override> _overrides(
  SubscriptionDashboard dash, {
  bool packsEnabled = true,
  int activeMembers = 0,
}) =>
    [
      homeTiersEnabledProvider.overrideWithValue(true),
      memberPacksEnabledProvider.overrideWithValue(packsEnabled),
      authProvider.overrideWith(() => _FakeAuth()),
      subscriptionDashboardProvider().overrideWith((_) => Stream.value(dash)),
      paywallProvider.overrideWith(() => _FakePaywall()),
      homeMembersProvider('h1')
          .overrideWith((_) => Stream.value(_members(activeMembers))),
    ];

Widget _wrap(Widget child,
        {required List<Override> overrides, Locale locale = const Locale('es')}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es'), Locale('en'), Locale('ro')],
        locale: locale,
        home: child,
      ),
    );

void main() {
  testWidgets('Grupo + flag ON + pagador con +10 activo: añadir y cancelar pack',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(maxMembers: 20, packs: const MemberPacks(plus10: true)),
        activeMembers: 12,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_add_pack')), findsOneWidget);
    expect(find.byKey(const Key('btn_cancel_pack_plus10')), findsOneWidget);
    // No hay botón de cancelar el +5 (no está activo).
    expect(find.byKey(const Key('btn_cancel_pack_plus5')), findsNothing);
  });

  testWidgets('PlanSummaryCard muestra la fila de packs con el tope efectivo',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(
            maxMembers: 25,
            packs: const MemberPacks(plus5: true, plus10: true)),
        activeMembers: 20,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan_packs_summary')), findsOneWidget);
    expect(find.textContaining('25'), findsWidgets);
  });

  testWidgets('Cancelar pack abre el diálogo de aviso de congelación',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(maxMembers: 20, packs: const MemberPacks(plus10: true)),
        activeMembers: 18,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('btn_cancel_pack_plus10')));
    await tester.tap(find.byKey(const Key('btn_cancel_pack_plus10')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack_cancel_dialog')), findsOneWidget);
    // 18 activos, nuevo tope 10 (20-10) → 8 congelados.
    expect(find.textContaining('8'), findsWidgets);
  });

  testWidgets('Descartar el diálogo de congelación lo cierra', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(maxMembers: 20, packs: const MemberPacks(plus10: true)),
        activeMembers: 18,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('btn_cancel_pack_plus10')));
    await tester.tap(find.byKey(const Key('btn_cancel_pack_plus10')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pack_cancel_dialog_dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pack_cancel_dialog')), findsNothing);
  });

  testWidgets('Flag OFF: sin gestión de packs ni fila de packs', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(maxMembers: 20, packs: const MemberPacks(plus10: true)),
        packsEnabled: false,
        activeMembers: 12,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_add_pack')), findsNothing);
    expect(find.byKey(const Key('btn_cancel_pack_plus10')), findsNothing);
    expect(find.byKey(const Key('plan_packs_summary')), findsNothing);
  });

  testWidgets('No-Grupo (Familia): sin gestión de packs', (tester) async {
    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(tier: 'familia', maxMembers: 5),
        activeMembers: 4,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('btn_add_pack')), findsNothing);
  });

  testWidgets('golden: gestión con packs activos (es)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(
      const SubscriptionManagementScreenV2(),
      overrides: _overrides(
        _dashboard(
            maxMembers: 25,
            packs: const MemberPacks(plus5: true, plus10: true)),
        activeMembers: 20,
      ),
    ));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/subscription_management_packs.png'),
    );
  });
}
