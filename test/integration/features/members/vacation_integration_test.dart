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
    const homeId = 'h1';
    const uid = 'u1';

    test('saveVacation escribe el campo `vacation` y NO modifica `status` '
        '(la ausencia la calcula el backend en lectura)', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'status': 'active', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: uid,
        homeId: homeId,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation(homeId, uid, vacation);

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      // El cliente solo persiste `vacation` (lo único que permiten las rules);
      // `status` no se toca — la ausencia efectiva la deriva el backend.
      expect(doc.data()!['status'], 'active');
      expect(doc.data()!['vacation']['isActive'], true);
    });

    test('saveVacation con isActive=false persiste vacation.isActive=false '
        'sin tocar `status`', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'status': 'active', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: uid,
        homeId: homeId,
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation(homeId, uid, vacation);

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      expect(doc.data()!['status'], 'active');
      expect(doc.data()!['vacation']['isActive'], false);
    });

    test('watchVacation emite null si no hay campo vacation', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'status': 'active'});

      final stream = repo.watchVacation(homeId, uid);
      expect(await stream.first, isNull);
    });

    test('saveVacation con isActive=true y startDate futuro → status permanece active', () async {
      await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .set({'status': 'active', 'nickname': 'Test'});

      final vacation = Vacation(
        uid: uid,
        homeId: homeId,
        isActive: true,
        startDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime(2026, 1, 1),
      );

      await repo.saveVacation(homeId, uid, vacation);

      final doc = await fakeFirestore
          .collection('homes').doc(homeId)
          .collection('members').doc(uid)
          .get();
      // isAbsent is false because startDate is in the future
      expect(doc.data()!['status'], 'active');
      expect(doc.data()!['vacation']['isActive'], true);
    });
  });
}
