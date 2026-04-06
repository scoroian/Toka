import 'user_profile.dart';

abstract interface class ProfileRepository {
  /// Lee el perfil del usuario desde `users/{uid}`.
  Future<UserProfile> fetchProfile(String uid);

  /// Escucha cambios en el perfil del usuario en tiempo real.
  Stream<UserProfile> watchProfile(String uid);

  /// Actualiza los campos proporcionados en `users/{uid}`.
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  });
}
