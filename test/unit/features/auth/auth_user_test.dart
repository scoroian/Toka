import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/domain/auth_user.dart';

class _MockUser extends Mock implements User {}

class _MockUserInfo extends Mock implements UserInfo {}

void main() {
  group('AuthUser.fromFirebaseUser', () {
    test('maps all fields correctly', () {
      final mockUserInfo = _MockUserInfo();
      when(() => mockUserInfo.providerId).thenReturn('google.com');

      final mockUser = _MockUser();
      when(() => mockUser.uid).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('test@example.com');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
      when(() => mockUser.emailVerified).thenReturn(true);
      when(() => mockUser.providerData).thenReturn([mockUserInfo]);

      final authUser = AuthUser.fromFirebaseUser(mockUser);

      expect(authUser.uid, 'user-123');
      expect(authUser.email, 'test@example.com');
      expect(authUser.displayName, 'Test User');
      expect(authUser.photoUrl, 'https://example.com/photo.jpg');
      expect(authUser.emailVerified, isTrue);
      expect(authUser.providers, ['google.com']);
    });

    test('providers list is empty when providerData is empty', () {
      final mockUser = _MockUser();
      when(() => mockUser.uid).thenReturn('uid-456');
      when(() => mockUser.email).thenReturn(null);
      when(() => mockUser.displayName).thenReturn(null);
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockUser.emailVerified).thenReturn(false);
      when(() => mockUser.providerData).thenReturn([]);

      final authUser = AuthUser.fromFirebaseUser(mockUser);

      expect(authUser.providers, isEmpty);
      expect(authUser.email, isNull);
    });

    test('two AuthUsers with same data are equal', () {
      const a = AuthUser(
        uid: 'u',
        email: 'a@a.com',
        displayName: 'A',
        photoUrl: null,
        emailVerified: true,
        providers: ['password'],
      );
      const b = AuthUser(
        uid: 'u',
        email: 'a@a.com',
        displayName: 'A',
        photoUrl: null,
        emailVerified: true,
        providers: ['password'],
      );
      expect(a, b);
    });
  });
}
