import 'package:firebase_auth/firebase_auth.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String uid,
    required String? email,
    required String? displayName,
    required String? photoUrl,
    required bool emailVerified,
    required List<String> providers,
  }) = _AuthUser;

  factory AuthUser.fromFirebaseUser(User user) => AuthUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        emailVerified: user.emailVerified,
        providers: user.providerData.map((p) => p.providerId).toList(),
      );
}
