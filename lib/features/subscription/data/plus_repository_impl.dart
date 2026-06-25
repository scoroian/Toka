import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/plus_entitlement.dart';
import '../domain/plus_repository.dart';

class PlusRepositoryImpl implements PlusRepository {
  PlusRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<PlusEntitlement?> watch(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('entitlements')
        .doc('plus')
        .snapshots()
        .map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return PlusEntitlement.fromMap(data);
    });
  }
}
