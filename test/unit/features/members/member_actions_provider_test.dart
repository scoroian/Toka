import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/application/member_actions_provider.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/members_repository.dart';

class _MockMembersRepository extends Mock implements MembersRepository {}

void main() {
  late _MockMembersRepository repo;

  setUp(() {
    repo = _MockMembersRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        membersRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('MemberActions.transferOwnership', () {
    // Regresión bug #12 (QA 2026-06-16): el método usaba AsyncValue.guard, que
    // capturaba la excepción y NO la relanzaba, por lo que la UI nunca veía el
    // payer-lock y mostraba un falso "éxito". Debe relanzar.
    test('relanza PayerLockedException y deja el estado en error', () async {
      when(() => repo.transferOwnership('h1', 'u2'))
          .thenThrow(const PayerLockedException());

      final container = makeContainer();
      final notifier = container.read(memberActionsProvider.notifier);

      await expectLater(
        () => notifier.transferOwnership('h1', 'u2'),
        throwsA(isA<PayerLockedException>()),
      );
      expect(container.read(memberActionsProvider).hasError, isTrue);
    });

    test('caso feliz deja el estado en data y no lanza', () async {
      when(() => repo.transferOwnership('h1', 'u2')).thenAnswer((_) async {});

      final container = makeContainer();
      final notifier = container.read(memberActionsProvider.notifier);

      await expectLater(notifier.transferOwnership('h1', 'u2'), completes);
      expect(container.read(memberActionsProvider).hasValue, isTrue);
      verify(() => repo.transferOwnership('h1', 'u2')).called(1);
    });
  });
}
