import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/subscription/data/plus_repository_impl.dart';

DocumentReference<Map<String, dynamic>> _plusRef(
  FakeFirebaseFirestore ff,
  String uid,
) =>
    ff.collection('users').doc(uid).collection('entitlements').doc('plus');

void main() {
  group('PlusRepositoryImpl.watch', () {
    test('emite null si el doc no existe', () async {
      final ff = FakeFirebaseFirestore();
      final repo = PlusRepositoryImpl(ff);

      final value = await repo.watch('u1').first;
      expect(value, isNull);
    });

    test('emite el entitlement parseado cuando el doc existe', () async {
      final ff = FakeFirebaseFirestore();
      await _plusRef(ff, 'u1').set({
        'status': 'active',
        'active': true,
        'cycle': 'annual',
        'productId': 'toka_plus_annual',
      });
      final repo = PlusRepositoryImpl(ff);

      final value = await repo.watch('u1').first;
      expect(value, isNotNull);
      expect(value!.active, isTrue);
      expect(value.cycle, 'annual');
      expect(value.productId, 'toka_plus_annual');
    });

    test('reacciona cuando el doc se crea después', () async {
      final ff = FakeFirebaseFirestore();
      final repo = PlusRepositoryImpl(ff);

      final emissions = <bool?>[];
      final sub = repo.watch('u1').listen((e) => emissions.add(e?.active));
      await Future<void>.delayed(Duration.zero);

      await _plusRef(ff, 'u1').set({'status': 'active', 'active': true});
      await Future<void>.delayed(Duration.zero);

      await sub.cancel();
      expect(emissions.first, isNull); // sin doc al principio
      expect(emissions.last, isTrue); // tras crearse, activo
    });
  });
}
