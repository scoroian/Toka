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
    // Usa update() para evitar crear el documento si no existe.
    // El documento members/{uid} solo lo crea una Cloud Function.
    await _memberRef(prefs.homeId, prefs.uid).update(
      {'notificationPrefs': prefs.toMap()},
    );
  }

  @override
  Future<void> updateFcmToken(String homeId, String uid, String token) async {
    // PRIVACIDAD (Hallazgo #01): el token FCM es un secreto de dispositivo, no
    // un dato del hogar. Antes se escribía en homes/{homeId}/members/{uid}
    // (legible por todo el hogar). Ahora se guarda en el doc privado
    // users/{uid}.fcmToken (allow read: if isUser(uid)). El homeId se ignora: el
    // token es por usuario, no por hogar (y así sirve para todos sus hogares).
    await _firestore.collection('users').doc(uid).set(
      {'fcmToken': token},
      SetOptions(merge: true),
    );
  }
}
