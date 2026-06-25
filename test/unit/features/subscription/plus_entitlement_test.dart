import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/domain/plus_entitlement.dart';

void main() {
  group('PlusEntitlement.fromMap', () {
    test('parsea un doc completo con Timestamps', () {
      final ent = PlusEntitlement.fromMap({
        'status': 'active',
        'active': true,
        'cycle': 'annual',
        'startsAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'endsAt': Timestamp.fromDate(DateTime(2027, 1, 1)),
        'autoRenewEnabled': true,
        'productId': 'toka_plus_annual',
      });

      expect(ent.status, 'active');
      expect(ent.active, isTrue);
      expect(ent.cycle, 'annual');
      expect(ent.startsAt, DateTime(2026, 1, 1));
      expect(ent.endsAt, DateTime(2027, 1, 1));
      expect(ent.autoRenewEnabled, isTrue);
      expect(ent.productId, 'toka_plus_annual');
      expect(ent.isAnnual, isTrue);
    });

    test('campos ausentes caen a valores seguros (sin Plus)', () {
      final ent = PlusEntitlement.fromMap(<String, dynamic>{});

      expect(ent.status, '');
      expect(ent.active, isFalse);
      expect(ent.cycle, isNull);
      expect(ent.startsAt, isNull);
      expect(ent.endsAt, isNull);
      expect(ent.autoRenewEnabled, isFalse);
      expect(ent.productId, isNull);
      expect(ent.isAnnual, isFalse);
    });

    test('respeta active=false explícito y ciclo mensual', () {
      final ent = PlusEntitlement.fromMap({
        'status': 'refunded',
        'active': false,
        'cycle': 'monthly',
        'productId': 'toka_plus_monthly',
      });

      expect(ent.status, 'refunded');
      expect(ent.active, isFalse);
      expect(ent.cycle, 'monthly');
      expect(ent.isAnnual, isFalse);
    });

    test('tolera tipos numéricos en active ausente y endsAt nulo explícito', () {
      final ent = PlusEntitlement.fromMap({
        'status': 'cancelledPendingEnd',
        'active': true,
        'endsAt': null,
        'cycle': 'annual',
      });

      expect(ent.status, 'cancelledPendingEnd');
      expect(ent.active, isTrue);
      expect(ent.endsAt, isNull);
    });
  });
}
