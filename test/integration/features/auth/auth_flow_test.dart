// Uses firebase_auth_mocks + mock_exceptions — no real emulators needed.
// Run with: flutter test test/integration/features/auth/auth_flow_test.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/data/auth_repository_impl.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

void main() {
  late _MockGoogleSignIn mockGoogleSignIn;

  setUpAll(() {
    mockGoogleSignIn = _MockGoogleSignIn();
    when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
  });

  group('registration with email/password', () {
    test('registers user and returns AuthUser with correct email', () async {
      final mockFirebaseAuth = MockFirebaseAuth(
        mockUser: MockUser(
          uid: 'new-user-uid',
          email: 'new@user.com',
          isEmailVerified: false,
        ),
      );
      final repo = AuthRepositoryImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      final user =
          await repo.registerWithEmailPassword('new@user.com', 'password123');

      expect(user.uid, isNotEmpty);
      expect(user.email, 'new@user.com');
    });
  });

  group('login with email/password', () {
    test('login returns correct AuthUser', () async {
      final mockFirebaseAuth = MockFirebaseAuth(
        signedIn: false,
        mockUser: MockUser(uid: 'existing-uid', email: 'user@user.com'),
      );
      final repo = AuthRepositoryImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      final user =
          await repo.signInWithEmailPassword('user@user.com', 'correctpass');

      expect(user.uid, 'existing-uid');
      expect(user.email, 'user@user.com');
    });
  });

  group('login with wrong credentials', () {
    test('throws AuthFailure.invalidCredentials', () async {
      final mockFirebaseAuth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid', email: 'x@x.com'),
      );
      whenCalling(Invocation.method(
        #signInWithEmailAndPassword,
        null,
        {#email: 'x@x.com', #password: 'wrong'},
      )).on(mockFirebaseAuth).thenThrow(
            FirebaseAuthException(code: 'wrong-password'),
          );

      final repo = AuthRepositoryImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      await expectLater(
        () => repo.signInWithEmailPassword('x@x.com', 'wrong'),
        throwsA(const AuthFailure.invalidCredentials()),
      );
    });
  });

  group('signOut', () {
    test('currentUser is null after signOut', () async {
      final mockFirebaseAuth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'uid', email: 'u@u.com'),
      );
      final repo = AuthRepositoryImpl(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
      );

      expect(mockFirebaseAuth.currentUser, isNotNull);

      await repo.signOut();

      expect(mockFirebaseAuth.currentUser, isNull);
    });
  });
}
