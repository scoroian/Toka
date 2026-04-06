import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<UserProfile> fetchProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw ServerException('User $uid not found');
    return UserProfile.fromMap(uid, doc.data()!);
  }

  @override
  Stream<UserProfile> watchProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .where((snap) => snap.exists)
        .map((snap) => UserProfile.fromMap(uid, snap.data()!));
  }

  @override
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  }) async {
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (phoneVisibility != null) updates['phoneVisibility'] = phoneVisibility;
    if (updates.isEmpty) return;
    await _firestore.collection('users').doc(uid).update(updates);
  }
}
