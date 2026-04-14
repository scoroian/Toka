import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/onboarding/domain/home_creation_repository.dart';

class _FakeHomeCreationRepo extends Fake implements HomeCreationRepository {
  _FakeHomeCreationRepo.returns(String homeId)
      : _homeId = homeId,
        _error = null;
  _FakeHomeCreationRepo.throws(Object error)
      : _homeId = null,
        _error = error;

  final String? _homeId;
  final Object? _error;

  @override
  Future<String> createHome({required String name, String? emoji}) async {
    if (_error != null) throw _error;
    return _homeId!;
  }

  @override
  Future<String> joinHome({required String code}) async {
    if (_error != null) throw _error;
    return _homeId!;
  }
}

void main() {
  test('createHome returns homeId', () async {
    final repo = _FakeHomeCreationRepo.returns('home-123');
    final result = await repo.createHome(name: 'Casa Test');
    expect(result, 'home-123');
  });

  test('createHome throws NoHomeSlotsException when no slots', () async {
    final repo = _FakeHomeCreationRepo.throws(const NoHomeSlotsException());
    await expectLater(
      () => repo.createHome(name: 'Casa'),
      throwsA(isA<NoHomeSlotsException>()),
    );
  });

  test('joinHome with invalid code throws InvalidInviteCodeException', () async {
    final repo =
        _FakeHomeCreationRepo.throws(const InvalidInviteCodeException());
    await expectLater(
      () => repo.joinHome(code: 'XXXXXX'),
      throwsA(isA<InvalidInviteCodeException>()),
    );
  });

  test('joinHome with expired code throws ExpiredInviteCodeException', () async {
    final repo =
        _FakeHomeCreationRepo.throws(const ExpiredInviteCodeException());
    await expectLater(
      () => repo.joinHome(code: 'EXPIRD'),
      throwsA(isA<ExpiredInviteCodeException>()),
    );
  });
}
