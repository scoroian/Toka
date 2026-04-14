import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/profile_repository.dart';
import '../domain/user_profile.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

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
        .map((snap) => snap.exists
            ? UserProfile.fromMap(uid, snap.data()!)
            : UserProfile(
                uid: uid,
                nickname: '',
                photoUrl: null,
                bio: null,
                phone: null,
                phoneVisibility: 'hidden',
                locale: 'es',
              ));
  }

  @override
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
    String? photoLocalPath,
  }) async {
    final updates = <String, dynamic>{};
    if (nickname != null) updates['nickname'] = nickname;
    if (bio != null) updates['bio'] = bio;
    if (phone != null) updates['phone'] = phone;
    if (phoneVisibility != null) updates['phoneVisibility'] = phoneVisibility;
    if (photoLocalPath != null) {
      final ref = _storage.ref('users/$uid/profile.jpg');
      await ref.putFile(File(photoLocalPath));
      updates['photoUrl'] = await ref.getDownloadURL();
    }
    if (updates.isEmpty) return;
    // set(merge:true) crea el documento si no existe, en lugar de lanzar
    // una excepción como haría update() en documentos nuevos.
    await _firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));
  }
}
