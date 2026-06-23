import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/support/data/support_repository_impl.dart';
import 'package:toka/features/support/domain/support_repository.dart';

class _MockFunctions extends Mock implements FirebaseFunctions {}

class _MockCallable extends Mock implements HttpsCallable {}

class _MockResult extends Mock implements HttpsCallableResult<Object?> {}

void main() {
  late _MockFunctions functions;
  late _MockCallable callable;

  setUp(() {
    functions = _MockFunctions();
    callable = _MockCallable();
    when(() => functions.httpsCallable(any())).thenReturn(callable);
  });

  SupportRepositoryImpl repo() => SupportRepositoryImpl(functions: functions);

  test('parsea el payload (incluso con Map/List anidados del plugin)', () async {
    // El plugin cloud_functions entrega objetos anidados como
    // Map<Object?,Object?> / List<Object?>. Verificamos que la coerción
    // profunda funciona y no lanza.
    final result = _MockResult();
    when(() => result.data).thenReturn(<Object?, Object?>{
      'homeId': 'home-1',
      'generatedAt': '2026-06-22T10:00:00.000Z',
      'home': <Object?, Object?>{
        'name': 'Casa QA',
        'premiumStatus': 'active',
        'ownerUid': 'owner',
      },
      'memberCount': 1,
      'members': <Object?>[
        <Object?, Object?>{
          'uid': 'm1',
          'nickname': 'Miembro',
          'role': 'owner',
          'hasPhone': true,
          'hasFcmToken': false,
          'tasksCompleted': 4,
          'averageScore': 7.5,
        },
      ],
      'upcomingTasks': <Object?>[
        <Object?, Object?>{'taskId': 't1', 'title': 'Fregar'},
      ],
      'recentEvents': <Object?>[
        <Object?, Object?>{'eventId': 'e1', 'eventType': 'completed'},
      ],
    });
    when(() => callable.call<Object?>(any())).thenAnswer((_) async => result);

    final d = await repo().diagnoseHome('home-1');

    expect(d.homeId, 'home-1');
    expect(d.home!.premiumStatus, 'active');
    expect(d.memberCount, 1);
    expect(d.members.single.uid, 'm1');
    expect(d.members.single.hasPhone, true);
    expect(d.members.single.hasFcmToken, false);
    expect(d.members.single.averageScore, 7.5);
    expect(d.upcomingTasks.single.taskId, 't1');
    expect(d.recentEvents.single.eventId, 'e1');
  });

  test('home null → estructura vacía sin lanzar', () async {
    final result = _MockResult();
    when(() => result.data).thenReturn(<Object?, Object?>{
      'homeId': 'ghost',
      'home': null,
      'memberCount': 0,
      'members': <Object?>[],
      'upcomingTasks': <Object?>[],
      'recentEvents': <Object?>[],
    });
    when(() => callable.call<Object?>(any())).thenAnswer((_) async => result);

    final d = await repo().diagnoseHome('ghost');
    expect(d.home, isNull);
    expect(d.members, isEmpty);
  });

  test('FirebaseFunctionsException → SupportException con el mismo code', () async {
    when(() => callable.call<Object?>(any())).thenThrow(
      FirebaseFunctionsException(message: 'denied', code: 'permission-denied'),
    );

    expect(
      () => repo().diagnoseHome('home-1'),
      throwsA(isA<SupportException>()
          .having((e) => e.code, 'code', 'permission-denied')),
    );
  });

  test('not-found se propaga como SupportException(not-found)', () async {
    when(() => callable.call<Object?>(any())).thenThrow(
      FirebaseFunctionsException(message: 'nope', code: 'not-found'),
    );

    expect(
      () => repo().diagnoseHome('x'),
      throwsA(isA<SupportException>().having((e) => e.code, 'code', 'not-found')),
    );
  });
}
