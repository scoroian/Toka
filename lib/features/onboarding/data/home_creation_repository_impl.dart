import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/home_creation_repository.dart';

class HomeCreationRepositoryImpl implements HomeCreationRepository {
  HomeCreationRepositoryImpl({
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
  })  : _functions = functions,
        _firestore = firestore;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  @override
  Future<String> createHome({required String name, String? emoji}) async {
    try {
      final callable = _functions.httpsCallable('createHome');
      final result = await callable.call<Map<String, dynamic>>({
        'name': name,
        if (emoji != null) 'emoji': emoji,
      });
      final data = result.data;
      return data['homeId'] as String;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'resource-exhausted') throw const NoHomeSlotsException();
      rethrow;
    }
  }

  @override
  Future<String> joinHome({required String code}) async {
    // Find invitation across all homes
    final query = await _firestore
        .collectionGroup('invitations')
        .where('code', isEqualTo: code)
        .where('used', isEqualTo: false)
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw const InvalidInviteCodeException();

    final doc = query.docs.first;
    final data = doc.data();

    final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw const ExpiredInviteCodeException();
    }

    // Extract homeId from document path: homes/{homeId}/invitations/{invId}
    final homeId = doc.reference.parent.parent!.id;

    // Mark invitation as used and create membership via callable
    final callable = _functions.httpsCallable('joinHome');
    await callable.call<void>({'homeId': homeId, 'invitationId': doc.id});

    return homeId;
  }
}
