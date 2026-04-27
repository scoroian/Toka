import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/failures/auth_failure.dart';
import 'exceptions/auth_exceptions.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<AuthUser?> get authStateChanges => _auth
      .authStateChanges()
      .map((u) => u != null ? AuthUser.fromFirebaseUser(u) : null);

  @override
  AuthUser? get currentUser {
    final u = _auth.currentUser;
    return u != null ? AuthUser.fromFirebaseUser(u) : null;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthCancelledException();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return AuthUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    } on AuthCancelledException {
      throw const AuthFailure.operationCancelled();
    }
  }

  @override
  Future<AuthUser> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final result = await _auth.signInWithCredential(oauthCredential);
      return AuthUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure.operationCancelled();
      }
      throw AuthFailure.unknown(e.message);
    }
  }

  @override
  Future<AuthUser> signInWithEmailPassword(
      String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<AuthUser> registerWithEmailPassword(
      String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthUser.fromFirebaseUser(result.user!);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> linkWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw const AuthCancelledException();
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    } on AuthCancelledException {
      throw const AuthFailure.operationCancelled();
    }
  }

  @override
  Future<void> linkWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      await _auth.currentUser?.linkWithCredential(oauthCredential);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure.operationCancelled();
      }
      throw AuthFailure.unknown(e.message);
    }
  }

  @override
  Future<void> linkWithEmailPassword(String email, String password) async {
    try {
      final credential =
          EmailAuthProvider.credential(email: email, password: password);
      await _auth.currentUser?.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw const AuthFailure.unknown('No current user');
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _map(e);
    }
  }

  @override
  Future<void> signOut() async {
    // Paralelizamos para no encadenar latencias: si el usuario no se logueó
    // con Google, `_googleSignIn.signOut()` igualmente intenta limpiar y puede
    // tardar varios segundos (Google Play Services). El `try/catch` evita que
    // un fallo del lado Google bloquee la salida real (FirebaseAuth).
    Future<void> googleSafe() async {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Silenciamos: si Google falla, FirebaseAuth.signOut() es lo único
        // necesario para volver a la pantalla de login.
      }
    }

    await Future.wait<void>([googleSafe(), _auth.signOut()]);
  }

  AuthFailure _map(FirebaseAuthException e) => switch (e.code) {
        'network-request-failed' => const AuthFailure.networkError(),
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-email' =>
          const AuthFailure.invalidCredentials(),
        'email-already-in-use' => const AuthFailure.emailAlreadyInUse(),
        'user-not-found' => const AuthFailure.userNotFound(),
        'weak-password' => const AuthFailure.weakPassword(),
        'account-exists-with-different-credential' =>
          AuthFailure.accountExistsWithDifferentCredential(
            email: e.email ?? '',
            providers: [],
          ),
        'too-many-requests' => const AuthFailure.tooManyRequests(),
        _ => AuthFailure.unknown(e.message),
      };
}
