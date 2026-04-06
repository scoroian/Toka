import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';
import '../data/member_model.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';

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
  Future<String> generateInviteCode(String homeId) async {
    try {
      final result = await _functions
          .httpsCallable('generateInviteCode')
          .call<Map<String, dynamic>>({'homeId': homeId});
      return result.data['code'] as String;
    } on FirebaseFunctionsException {
      rethrow;
    }
  }

  @override
  Future<void> removeMember(String homeId, String uid) async {
    try {
      await _functions.httpsCallable('removeMember').call({
        'homeId': homeId,
        'targetUid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition') throw const CannotRemoveOwnerException();
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
}
