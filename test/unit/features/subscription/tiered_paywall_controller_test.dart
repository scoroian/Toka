import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/homes/application/dashboard_provider.dart';
import 'package:toka/features/subscription/application/tiered_paywall_controller.dart';
import 'package:toka/features/subscription/domain/tier_catalog.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';

HomeDashboard _dashboard({String? tier, bool isPremium = false, int members = 0}) {
  return HomeDashboard.fromFirestore({
    'activeTasksPreview': [],
    'doneTasksPreview': [],
    'counters': {},
    'planCounters': {'activeMembers': members},
    'memberPreview': [],
    'premiumFlags': {'isPremium': isPremium, if (tier != null) 'tier': tier},
    'adFlags': {},
    'rescueFlags': {},
    'updatedAt': Timestamp.fromDate(DateTime(2026, 6, 1)),
  });
}

Future<ProviderContainer> _container(HomeDashboard? dashboard) async {
  final container = ProviderContainer(
    overrides: [
      dashboardProvider.overrideWith((ref) => Stream.value(dashboard)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(dashboardProvider.future);
  return container;
}

void main() {
  group('TieredPaywallController defaults', () {
    test('hogar premium → preselecciona el tier actual', () async {
      final c = await _container(
          _dashboard(tier: 'grupo', isPremium: true, members: 8));
      final sel = c.read(tieredPaywallControllerProvider);
      expect(sel.tier, HomeTier.grupo);
      expect(sel.cycle, BillingCycle.annual);
    });

    test('hogar no premium → preselecciona el menor tier que cabe sus miembros',
        () async {
      final c = await _container(_dashboard(members: 4));
      final sel = c.read(tieredPaywallControllerProvider);
      expect(sel.tier, HomeTier.familia); // 4 miembros → Familia (5)
    });

    test('hogar no premium con 0 miembros → Pareja (menor tier)', () async {
      final c = await _container(_dashboard(members: 0));
      final sel = c.read(tieredPaywallControllerProvider);
      expect(sel.tier, HomeTier.pareja);
    });

    test('sin dashboard → Pareja, anual (default seguro)', () async {
      final c = await _container(null);
      final sel = c.read(tieredPaywallControllerProvider);
      expect(sel.tier, HomeTier.pareja);
      expect(sel.cycle, BillingCycle.annual);
    });
  });

  group('TieredPaywallController interacción', () {
    test('selectTier cambia el tier seleccionado', () async {
      final c = await _container(_dashboard(members: 1));
      c.read(tieredPaywallControllerProvider.notifier).selectTier(HomeTier.grupo);
      expect(c.read(tieredPaywallControllerProvider).tier, HomeTier.grupo);
    });

    test('selectCycle alterna mensual/anual', () async {
      final c = await _container(_dashboard(members: 1));
      c
          .read(tieredPaywallControllerProvider.notifier)
          .selectCycle(BillingCycle.monthly);
      expect(c.read(tieredPaywallControllerProvider).cycle, BillingCycle.monthly);
    });

    test('seleccionar tier no resetea el ciclo y viceversa', () async {
      final c = await _container(_dashboard(members: 1));
      final notifier = c.read(tieredPaywallControllerProvider.notifier);
      notifier.selectCycle(BillingCycle.monthly);
      notifier.selectTier(HomeTier.familia);
      final sel = c.read(tieredPaywallControllerProvider);
      expect(sel.tier, HomeTier.familia);
      expect(sel.cycle, BillingCycle.monthly);
    });
  });
}
