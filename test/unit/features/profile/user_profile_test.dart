import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

void main() {
  test('UserProfile se construye correctamente', () {
    const profile = UserProfile(
      uid: 'uid1',
      nickname: 'Ana',
      photoUrl: null,
      bio: 'Bio de prueba',
      phone: '123456789',
      phoneVisibility: 'sameHomeMembers',
      locale: 'es',
    );
    expect(profile.uid, 'uid1');
    expect(profile.phoneVisibility, 'sameHomeMembers');
  });

  test('UserProfile.fromMap mapea campos opcionales como null', () {
    final profile = UserProfile.fromMap('uid2', {
      'nickname': 'Bob',
      'locale': 'en',
    });
    expect(profile.bio, isNull);
    expect(profile.phone, isNull);
    expect(profile.phoneVisibility, 'hidden');
  });

  test('UserProfile.fromMap usa locale por defecto es cuando falta', () {
    final profile = UserProfile.fromMap('uid3', {'nickname': 'Carlos'});
    expect(profile.locale, 'es');
  });

  test('UserProfile.fromMap usa nickname vacío cuando falta', () {
    final profile = UserProfile.fromMap('uid4', {});
    expect(profile.nickname, isEmpty);
  });
}
