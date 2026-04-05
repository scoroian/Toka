import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/home.dart';
import '../domain/home_limits.dart';
import '../domain/home_membership.dart';

class HomeModel {
  static Home fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Home(
      id: doc.id,
      name: data['name'] as String,
      ownerUid: data['ownerUid'] as String,
      currentPayerUid: data['currentPayerUid'] as String?,
      lastPayerUid: data['lastPayerUid'] as String?,
      premiumStatus: HomePremiumStatus.fromString(
          data['premiumStatus'] as String? ?? 'free'),
      premiumPlan: data['premiumPlan'] as String?,
      premiumEndsAt: (data['premiumEndsAt'] as Timestamp?)?.toDate(),
      restoreUntil: (data['restoreUntil'] as Timestamp?)?.toDate(),
      autoRenewEnabled: data['autoRenewEnabled'] as bool? ?? false,
      limits: HomeLimits(
        maxMembers: (data['limits']?['maxMembers'] as int?) ?? 5,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
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
    );
  }
}
