import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmailPassword(String email, String password);
  Future<AuthUser> registerWithEmailPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> linkWithGoogle();
  Future<void> linkWithApple();
  Future<void> linkWithEmailPassword(String email, String password);
  Future<void> updatePassword(String currentPassword, String newPassword);
  Future<void> signOut();
}
