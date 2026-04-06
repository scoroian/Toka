import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/profile/domain/profile_repository.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repo;

  const fakeProfile = UserProfile(
    uid: 'uid1',
    nickname: 'Ana',
    photoUrl: null,
    bio: null,
    phone: null,
    phoneVisibility: 'hidden',
    locale: 'es',
  );

  setUp(() {
    repo = _MockProfileRepository();
  });

  test('fetchProfile retorna UserProfile', () async {
    when(() => repo.fetchProfile('uid1'))
        .thenAnswer((_) async => fakeProfile);
    final profile = await repo.fetchProfile('uid1');
    expect(profile.uid, 'uid1');
    expect(profile.nickname, 'Ana');
  });

  test('updateProfile completa sin error', () async {
    when(() => repo.updateProfile('uid1',
            nickname: any(named: 'nickname'),
            bio: any(named: 'bio'),
            phone: any(named: 'phone'),
            phoneVisibility: any(named: 'phoneVisibility')))
        .thenAnswer((_) async {});
    await expectLater(
      repo.updateProfile('uid1', nickname: 'Ana Nueva'),
      completes,
    );
  });

  test('watchProfile emite UserProfile', () {
    when(() => repo.watchProfile('uid1'))
        .thenAnswer((_) => Stream.value(fakeProfile));
    expect(repo.watchProfile('uid1'), emits(fakeProfile));
  });
}
