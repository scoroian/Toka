abstract class OnboardingRepository {
  /// Saves the user profile to Firestore and optionally uploads a photo to Storage.
  /// Returns the final photoUrl (null if no photo was provided).
  Future<String?> saveProfile({
    required String uid,
    required String nickname,
    String? phoneNumber,
    required bool phoneVisible,
    String? photoLocalPath,
    required String locale,
  });
}
