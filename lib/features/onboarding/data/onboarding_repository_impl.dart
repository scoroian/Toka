import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  OnboardingRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<String?> saveProfile({
    required String uid,
    required String nickname,
    String? phoneNumber,
    required bool phoneVisible,
    String? photoLocalPath,
    required String locale,
  }) async {
    String? photoUrl;

    if (photoLocalPath != null) {
      final ref = _storage.ref('users/$uid/profile.jpg');
      await ref.putFile(File(photoLocalPath));
      photoUrl = await ref.getDownloadURL();
    }

    final data = <String, dynamic>{
      'nickname': nickname,
      'locale': locale,
      'phoneVisibility': phoneVisible ? 'sameHomeMembers' : 'hidden',
    };
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      data['phone'] = phoneNumber;
    }
    if (photoUrl != null) {
      data['photoUrl'] = photoUrl;
    }

    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));

    return photoUrl;
  }
}
