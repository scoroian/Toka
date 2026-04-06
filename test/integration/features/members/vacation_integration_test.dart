// test/integration/features/members/vacation_integration_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/data/members_repository_impl.dart';
import 'package:toka/features/members/domain/vacation.dart';

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MembersRepositoryImpl repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    repo = MembersRepositoryImpl(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('Vacation integration', () {
    test('saveVacation guarda el campo vacation y cambia status a absent', () async {
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'active', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: 'u1',
        homeId: 'h1',
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation('h1', 'u1', vacation);

      final doc = await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .get();
      expect(doc.data()!['status'], 'absent');
      expect(doc.data()!['vacation']['isActive'], true);
    });

    test('saveVacation con isAbsent false restaura status a active', () async {
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'absent', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: 'u1',
        homeId: 'h1',
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation('h1', 'u1', vacation);

      final doc = await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .get();
      expect(doc.data()!['status'], 'active');
    });

    test('watchVacation emite null si no hay campo vacation', () async {
      await fakeFirestore
          .collection('homes').doc('h1')
          .collection('members').doc('u1')
          .set({'status': 'active'});

      final stream = repo.watchVacation('h1', 'u1');
      expect(await stream.first, isNull);
    });
  });
}
