import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/free_limits.dart';
import '../domain/home.dart';
import '../domain/home_limits.dart';
import '../domain/home_membership.dart';

class HomeModel {
  static Home fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final premiumStatusRaw = data['premiumStatus'] as String? ?? 'free';
    final premiumStatus = normalizePremiumStatus(premiumStatusRaw);

    return Home(
      id: doc.id,
      name: data['name'] as String,
      ownerUid: data['ownerUid'] as String,
      currentPayerUid: data['currentPayerUid'] as String?,
      lastPayerUid: data['lastPayerUid'] as String?,
      premiumStatus: HomePremiumStatus.fromString(premiumStatus),
      premiumPlan: data['premiumPlan'] as String?,
      premiumEndsAt: (data['premiumEndsAt'] as Timestamp?)?.toDate(),
      restoreUntil: (data['restoreUntil'] as Timestamp?)?.toDate(),
      autoRenewEnabled: data['autoRenewEnabled'] as bool? ?? false,
      limits: HomeLimits(
        maxMembers: (data['limits']?['maxMembers'] as int?) ?? 5,
        isPremium: isHomePremium(premiumStatus),
      ),
      // `createdAt`/`updatedAt` pueden venir `null` en la emisión optimista
      // del dispositivo que acaba de escribir con `FieldValue.serverTimestamp()`
      // (latency compensation): el snapshot local llega antes de que el servidor
      // resuelva el timestamp. Toleramos ese estado transitorio; el siguiente
      // snapshot confirmado traerá el valor real.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastBillingError: data['lastBillingError'] as String?,
      photoUrl: data['photoUrl'] as String?,
      timezone: data['timezone'] as String? ?? 'Europe/Madrid',
    );
  }

  static HomeMembership membershipFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HomeMembership(
      homeId: doc.id,
      homeNameSnapshot: data['homeNameSnapshot'] as String,
      role: MemberRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      billingState: BillingState.values.firstWhere(
        (e) => e.name == (data['billingState'] as String? ?? 'none'),
        orElse: () => BillingState.none,
      ),
      status: MemberStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => MemberStatus.active,
      ),
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
      leftAt: (data['leftAt'] as Timestamp?)?.toDate(),
      hasPendingToday: data['hasPendingToday'] as bool? ?? false,
      homePhotoSnapshot: data['homePhotoSnapshot'] as String?,
    );
  }
}
