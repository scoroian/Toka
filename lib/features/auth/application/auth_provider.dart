import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../features/i18n/application/locale_provider.dart';
import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import '../domain/failures/auth_failure.dart';
import '../../homes/application/current_home_provider.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(
    firebaseAuth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(),
  );
}

@Riverpod(keepAlive: true)
Stream<AuthUser?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.listen<AsyncValue<AuthUser?>>(
      authStateChangesProvider,
      (_, next) => next.whenData((user) {
        if (user != null) {
          state = AuthState.authenticated(user);
          ref.read(localeNotifierProvider.notifier).initialize(user.uid);
        } else {
          state = const AuthState.unauthenticated();
        }
      }),
    );
    return const AuthState.initial();
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AuthState.authenticated(user);
    } on AuthFailure catch (f) {
      state = AuthState.error(f);
    } catch (_) {
      state = const AuthState.error(AuthFailure.unknown());
    }
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    try {
      final user = await _repo.signInWithApple();
      state = AuthState.authenticated(user);
    } on AuthFailure catch (f) {
      state = AuthState.error(f);
    } catch (_) {
      state = const AuthState.error(AuthFailure.unknown());
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repo.signInWithEmailPassword(email, password);
      state = AuthState.authenticated(user);
    } on AuthFailure catch (f) {
      state = AuthState.error(f);
    } catch (_) {
      state = const AuthState.error(AuthFailure.unknown());
    }
  }

  Future<void> register(String email, String password) async {
    state = const AuthState.loading();
    try {
      await _repo.registerWithEmailPassword(email, password);
      await _repo.sendEmailVerification();
    } on AuthFailure catch (f) {
      state = AuthState.error(f);
    } catch (_) {
      state = const AuthState.error(AuthFailure.unknown());
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordResetEmail(email);
    } on AuthFailure catch (f) {
      state = AuthState.error(f);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    ref.invalidateSelf();
    // Invalidate after the current frame to avoid circular dependency
    // (currentHomeProvider watches authProvider, so it rebuilds on its own,
    // but explicit invalidation ensures stale cached data is cleared too).
    Future.microtask(() => ref.invalidate(currentHomeProvider));
  }
}
