// lib/features/notifications/data/notification_prefs_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/notification_preferences.dart';
import '../domain/notification_prefs_repository.dart';

class NotificationPrefsRepositoryImpl implements NotificationPrefsRepository {
  NotificationPrefsRepositoryImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _memberRef(String homeId, String uid) =>
      _firestore.collection('homes').doc(homeId).collection('members').doc(uid);

  @override
  Stream<NotificationPreferences> watchPrefs(String homeId, String uid) {
    return _memberRef(homeId, uid).snapshots().map((snap) {
      if (!snap.exists) {
        return NotificationPreferences(homeId: homeId, uid: uid);
      }
      final data = snap.data()!;
      final prefsMap = (data['notificationPrefs'] as Map<String, dynamic>?) ?? {};
      return NotificationPreferences.fromMap(homeId, uid, prefsMap);
    });
  }

  @override
  Future<void> savePrefs(NotificationPreferences prefs) async {
    await _memberRef(prefs.homeId, prefs.uid).update({
      'notificationPrefs': prefs.toMap(),
    });
  }

  @override
  Future<void> updateFcmToken(String homeId, String uid, String token) async {
    await _memberRef(homeId, uid).set(
      {'notificationPrefs': {'fcmToken': token}},
      SetOptions(merge: true),
    );
  }
}
