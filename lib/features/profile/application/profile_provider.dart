import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/profile_repository_impl.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  return ProfileRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    storage: FirebaseStorage.instance,
  );
}

@riverpod
Stream<UserProfile> userProfile(UserProfileRef ref, String uid) {
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
}

@riverpod
class ProfileEditor extends _$ProfileEditor {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
    String? photoLocalPath,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).updateProfile(
            uid,
            nickname: nickname,
            bio: bio,
            phone: phone,
            phoneVisibility: phoneVisibility,
            photoLocalPath: photoLocalPath,
          ),
    );
  }
}
