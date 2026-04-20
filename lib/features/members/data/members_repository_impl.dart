import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';
import '../data/member_model.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';
import '../domain/vacation.dart';

class MembersRepositoryImpl implements MembersRepository {
  MembersRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<Member>> watchHomeMembers(String homeId) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .where('status', isNotEqualTo: 'left')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MemberModel.fromFirestore(d, homeId)).toList());
  }

  @override
  Future<Member> fetchMember(String homeId, String uid) async {
    final doc = await _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid)
        .get();
    if (!doc.exists) throw ServerException('Member $uid not found in $homeId');
    return MemberModel.fromFirestore(doc, homeId);
  }

  @override
  Future<void> inviteMember(String homeId, String? email) async {
    try {
      await _functions.httpsCallable('inviteMember').call({
        'homeId': homeId,
        if (email != null) 'email': email,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const MaxMembersReachedException();
      rethrow;
    }
  }

  @override
  Future<({String code, DateTime expiresAt})> generateInviteCode(
      String homeId) async {
    final result = await _functions
        .httpsCallable('generateInviteCode')
        .call<Map<String, dynamic>>({'homeId': homeId});
    final code = result.data['code'] as String;
    final expiresAtIso = result.data['expiresAt'] as String?;
    final expiresAt = expiresAtIso != null
        ? DateTime.parse(expiresAtIso).toLocal()
        : DateTime.now().add(const Duration(days: 7));
    return (code: code, expiresAt: expiresAt);
  }

  @override
  Stream<({String code, DateTime expiresAt})?> watchActiveInviteCode(
      String homeId) {
    final now = DateTime.now();
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('invitations')
        .where('used', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final expiresAtTs = data['expiresAt'] as Timestamp?;
        if (expiresAtTs == null) continue;
        final expiresAt = expiresAtTs.toDate();
        if (expiresAt.isAfter(now)) {
          return (code: data['code'] as String, expiresAt: expiresAt.toLocal());
        }
      }
      return null;
    });
  }

  @override
  Future<void> removeMember(String homeId, String uid) async {
    try {
      await _functions.httpsCallable('removeMember').call({
        'homeId': homeId,
        'targetUid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') {
        if ((e.message ?? '')
            .contains('payer-cannot-leave-or-be-removed-while-premium-active')) {
          throw const PayerLockedException();
        }
        throw const CannotRemoveOwnerException();
      }
      rethrow;
    }
  }

  @override
  Future<void> promoteToAdmin(String homeId, String uid) async {
    try {
      await _functions.httpsCallable('promoteToAdmin').call({
        'homeId': homeId,
        'targetUid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const MaxAdminsReachedException();
      rethrow;
    }
  }

  @override
  Future<void> demoteFromAdmin(String homeId, String uid) async {
    await _functions.httpsCallable('demoteFromAdmin').call({
      'homeId': homeId,
      'targetUid': uid,
    });
  }

  @override
  Future<void> transferOwnership(String homeId, String newOwnerUid) async {
    await _functions.httpsCallable('transferOwnership').call({
      'homeId': homeId,
      'newOwnerUid': newOwnerUid,
    });
  }

  @override
  Future<void> saveVacation(String homeId, String uid, Vacation vacation) async {
    final memberRef = _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid);
    await memberRef.update({
      'vacation': vacation.toMap(),
      'status': vacation.isAbsent ? 'absent' : 'active',
    });
  }

  @override
  Stream<Vacation?> watchVacation(String homeId, String uid) {
    return _firestore
        .collection('homes')
        .doc(homeId)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final vacMap = data['vacation'] as Map<String, dynamic>?;
      if (vacMap == null) return null;
      return Vacation.fromMap(uid, homeId, vacMap);
    });
  }

  @override
  Future<void> submitReview({
    required String homeId,
    required String taskEventId,
    required double score,
    String? note,
  }) async {
    try {
      await _functions.httpsCallable('submitReview').call({
        'homeId': homeId,
        'taskEventId': taskEventId,
        'score': score,
        if (note != null) 'note': note,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') throw const AlreadyRatedException();
      rethrow;
    }
  }
}
