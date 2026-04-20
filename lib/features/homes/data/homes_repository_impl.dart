import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../core/errors/exceptions.dart';
import '../domain/home.dart';
import '../domain/home_membership.dart';
import '../domain/homes_repository.dart';
import 'home_model.dart';

class HomesRepositoryImpl implements HomesRepository {
  HomesRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<List<HomeMembership>> watchUserMemberships(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .where('status', whereIn: ['active', 'frozen'])
        .snapshots()
        .map((snap) =>
            snap.docs.map(HomeModel.membershipFromFirestore).toList());
  }

  @override
  Future<Home> fetchHome(String homeId) async {
    final doc = await _firestore.collection('homes').doc(homeId).get();
    if (!doc.exists) throw ServerException('Home $homeId not found');
    return HomeModel.fromFirestore(doc);
  }

  @override
  Future<String> createHome(String name) async {
    try {
      final callable = _functions.httpsCallable('createHome');
      final result = await callable.call<Map<String, dynamic>>({'name': name});
      return result.data['homeId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') {
        throw const NoAvailableSlotsException();
      }
      rethrow;
    }
  }

  @override
  Future<void> joinHome(String inviteCode) async {
    try {
      final callable = _functions.httpsCallable('joinHomeByCode');
      await callable.call<void>({'code': inviteCode});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found') throw const InvalidInviteCodeException();
      if (e.code == 'deadline-exceeded') throw const ExpiredInviteCodeException();
      rethrow;
    }
  }

  @override
  Future<void> leaveHome(String homeId, {required String uid}) async {
    final memberDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .doc(homeId)
        .get();

    if (memberDoc.exists) {
      final role = memberDoc.data()?['role'] as String?;
      if (role == 'owner') throw const CannotLeaveAsOwnerException();
    }

    final callable = _functions.httpsCallable('leaveHome');
    try {
      await callable.call<void>({'homeId': homeId});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' &&
          (e.message ?? '')
              .contains('payer-cannot-leave-or-be-removed-while-premium-active')) {
        throw const PayerLockedException();
      }
      rethrow;
    }
  }

  @override
  Future<void> closeHome(String homeId) async {
    final callable = _functions.httpsCallable('closeHome');
    await callable.call<void>({'homeId': homeId});
  }

  @override
  Future<void> updateLastSelectedHome(String uid, String homeId) async {
    await _firestore.collection('users').doc(uid).update({
      'lastSelectedHomeId': homeId,
    });
  }

  @override
  Future<int> getAvailableSlots(String uid) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return 0;
    final data = userDoc.data()!;
    final baseSlots = (data['baseSlots'] as int?) ?? 2;
    final lifetimeUnlocked = (data['lifetimeUnlocked'] as int?) ?? 0;

    final membershipsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('memberships')
        .where('status', whereIn: ['active', 'frozen'])
        .get();
    final currentCount = membershipsSnap.docs.length;

    return baseSlots + lifetimeUnlocked - currentCount;
  }

  @override
  Future<String?> getLastSelectedHomeId(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['lastSelectedHomeId'] as String?;
  }

  @override
  Future<void> updateHomeName(String homeId, String name) async {
    await _firestore.collection('homes').doc(homeId).update({'name': name});
  }

  // DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
  @override
  Future<void> debugSetPremiumStatus(String homeId, String status) async {
    final callable = _functions.httpsCallable('debugSetPremiumStatus');
    await callable.call<void>({'homeId': homeId, 'status': status});
  }
  // END DEBUG PREMIUM
}
