import 'package:cloud_firestore/cloud_firestore.dart';
import '../../homes/domain/home_membership.dart';
import '../domain/member.dart';

class MemberModel {
  static Member fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc, String homeId) {
    return fromMap(doc.id, homeId, doc.data()!);
  }

  static Member fromMap(
      String uid, String homeId, Map<String, dynamic> data) {
    return Member(
      uid: uid,
      homeId: homeId,
      nickname: data['nickname'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String?,
      phone: data['phone'] as String?,
      phoneVisibility:
          data['phoneVisibility'] as String? ?? 'hidden',
      role: MemberRole.values.firstWhere(
        (e) => e.name == (data['role'] as String? ?? 'member'),
        orElse: () => MemberRole.member,
      ),
      status: MemberStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'active'),
        orElse: () => MemberStatus.active,
      ),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      tasksCompleted: (data['tasksCompleted'] as int?) ?? 0,
      passedCount: (data['passedCount'] as int?) ?? 0,
      complianceRate:
          ((data['complianceRate'] as num?) ?? 0.0).toDouble(),
      currentStreak: (data['currentStreak'] as int?) ?? 0,
      averageScore:
          ((data['averageScore'] as num?) ?? 0.0).toDouble(),
    );
  }
}
