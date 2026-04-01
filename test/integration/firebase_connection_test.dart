// Uses fake_cloud_firestore — no real emulators needed.
// Run with: flutter test test/integration/firebase_connection_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firebase connection (fake_cloud_firestore)', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('can write and read a document', () async {
      await fakeFirestore
          .collection('_test')
          .doc('ping')
          .set({'value': 'pong'});

      final snap =
          await fakeFirestore.collection('_test').doc('ping').get();
      expect(snap.data()?['value'], equals('pong'));
    });

    test('can delete a document', () async {
      final ref = fakeFirestore.collection('_test').doc('to_delete');
      await ref.set({'x': 1});
      await ref.delete();

      final snap = await ref.get();
      expect(snap.exists, isFalse);
    });

    test('collection query returns added documents', () async {
      final col = fakeFirestore.collection('items');
      await col.add({'name': 'alpha'});
      await col.add({'name': 'beta'});

      final query = await col.get();
      expect(query.docs.length, equals(2));
    });
  });
}
