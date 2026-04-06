import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/data/auth_repository_impl.dart';
import 'package:toka/features/auth/domain/failures/auth_failure.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MockUser extends Mock implements User {}

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class _MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void _stubUser(
  _MockUser u, {
  String uid = 'uid',
  String? email = 'u@u.com',
  bool emailVerified = true,
}) {
  when(() => u.uid).thenReturn(uid);
  when(() => u.email).thenReturn(email);
  when(() => u.displayName).thenReturn(null);
  when(() => u.photoURL).thenReturn(null);
  when(() => u.emailVerified).thenReturn(emailVerified);
  when(() => u.providerData).thenReturn([]);
}

void main() {
  late _MockFirebaseAuth mockAuth;
  late _MockGoogleSignIn mockGoogleSignIn;
  late AuthRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuth = _MockFirebaseAuth();
    mockGoogleSignIn = _MockGoogleSignIn();
    when(() => mockAuth.authStateChanges())
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAuth.currentUser).thenReturn(null);
    repo = AuthRepositoryImpl(
      firebaseAuth: mockAuth,
      googleSignIn: mockGoogleSignIn,
    );
  });

  group('signInWithGoogle', () {
    test('returns AuthUser on success', () async {
      final mockGoogleAuth = _MockGoogleSignInAuthentication();
      when(() => mockGoogleAuth.accessToken).thenReturn('access');
      when(() => mockGoogleAuth.idToken).thenReturn('id');

      final mockAccount = _MockGoogleSignInAccount();
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);

      final mockUser = _MockUser();
      _stubUser(mockUser, uid: 'google-uid');

      final mockCredential = _MockUserCredential();
      when(() => mockCredential.user).thenReturn(mockUser);

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAuth.signInWithCredential(any()))
          .thenAnswer((_) async => mockCredential);

      final result = await repo.signInWithGoogle();
      expect(result.uid, 'google-uid');
    });

    test('throws AuthFailure.networkError on network failure', () async {
      final mockGoogleAuth = _MockGoogleSignInAuthentication();
      when(() => mockGoogleAuth.accessToken).thenReturn('access');
      when(() => mockGoogleAuth.idToken).thenReturn('id');

      final mockAccount = _MockGoogleSignInAccount();
      when(() => mockAccount.authentication)
          .thenAnswer((_) async => mockGoogleAuth);

      when(() => mockGoogleSignIn.signIn())
          .thenAnswer((_) async => mockAccount);
      when(() => mockAuth.signInWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'network-request-failed'),
      );

      await expectLater(
        () => repo.signInWithGoogle(),
        throwsA(const AuthFailure.networkError()),
      );
    });
  });

  group('signInWithEmailPassword', () {
    test('throws AuthFailure.invalidCredentials with wrong-password', () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      await expectLater(
        () => repo.signInWithEmailPassword('x@x.com', 'bad'),
        throwsA(const AuthFailure.invalidCredentials()),
      );
    });

    test('throws AuthFailure.invalidCredentials with invalid-credential',
        () async {
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

      await expectLater(
        () => repo.signInWithEmailPassword('x@x.com', 'bad'),
        throwsA(const AuthFailure.invalidCredentials()),
      );
    });
  });

  group('registerWithEmailPassword', () {
    test('throws AuthFailure.emailAlreadyInUse if email exists', () async {
      when(() => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        () => repo.registerWithEmailPassword('x@x.com', 'pass'),
        throwsA(const AuthFailure.emailAlreadyInUse()),
      );
    });
  });

  group('sendPasswordResetEmail', () {
    test('completes without error', () async {
      when(() =>
              mockAuth.sendPasswordResetEmail(email: any(named: 'email')))
          .thenAnswer((_) async {});

      await expectLater(repo.sendPasswordResetEmail('x@x.com'), completes);
    });
  });

  group('signOut', () {
    test('calls signOut on both googleSignIn and firebaseAuth', () async {
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => mockGoogleSignIn.signOut()).called(1);
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
