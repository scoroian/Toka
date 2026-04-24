// test/ui/features/subscription/plan_summary_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/subscription/domain/subscription_dashboard.dart';
import 'package:toka/features/subscription/presentation/widgets/plan_summary_card.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/l10n/app_localizations.dart';

const _referenceEndsAt = '2027-01-15';
const _referenceRestoreUntil = '2027-02-15';

SubscriptionDashboard _dashboard(
  HomePremiumStatus status, {
  String? plan = 'annual',
  bool withEndsAt = true,
  bool withRestoreUntil = false,
  bool autoRenew = true,
  String? payerUid = 'u1',
  PlanCounters? counters,
}) =>
    SubscriptionDashboard(
      homeId: 'h1',
      status: status,
      plan: plan,
      endsAt: withEndsAt ? DateTime.parse(_referenceEndsAt) : null,
      restoreUntil:
          withRestoreUntil ? DateTime.parse(_referenceRestoreUntil) : null,
      autoRenew: autoRenew,
      currentPayerUid: payerUid,
      planCounters: counters ?? PlanCounters.empty(),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es')],
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 360,
            child: child,
          ),
        ),
      ),
    );

void main() {
  testWidgets('golden: PlanSummaryCard estado free', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.free,
          plan: null,
          withEndsAt: false,
          autoRenew: false,
          payerUid: null,
          counters: const PlanCounters(
            activeMembers: 2,
            activeTasks: 0,
            automaticRecurringTasks: 1,
            totalAdmins: 1,
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile('goldens/plan_summary_card_free.png'),
    );
  });

  testWidgets('golden: PlanSummaryCard estado active', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(HomePremiumStatus.active),
        currentUserUid: 'u1',
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile('goldens/plan_summary_card_active.png'),
    );
  });

  testWidgets('golden: PlanSummaryCard estado cancelledPendingEnd', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.cancelledPendingEnd,
          autoRenew: false,
        ),
        currentUserUid: 'u1',
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile(
          'goldens/plan_summary_card_cancelled_pending_end.png'),
    );
  });

  testWidgets('golden: PlanSummaryCard estado rescue', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.rescue,
          autoRenew: false,
        ),
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile('goldens/plan_summary_card_rescue.png'),
    );
  });

  testWidgets('golden: PlanSummaryCard estado expiredFree', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.expiredFree,
          plan: null,
          autoRenew: false,
          payerUid: null,
        ),
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile('goldens/plan_summary_card_expired_free.png'),
    );
  });

  testWidgets('golden: PlanSummaryCard estado restorable', (t) async {
    await t.pumpWidget(_wrap(
      PlanSummaryCard(
        data: _dashboard(
          HomePremiumStatus.restorable,
          plan: null,
          withEndsAt: false,
          withRestoreUntil: true,
          autoRenew: false,
          payerUid: null,
        ),
      ),
    ));
    await t.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('plan_summary_card')),
      matchesGoldenFile('goldens/plan_summary_card_restorable.png'),
    );
  });
}
