import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/homes_repository_impl.dart';
import '../domain/home_membership.dart';
import '../domain/homes_repository.dart';

part 'homes_provider.g.dart';

@Riverpod(keepAlive: true)
HomesRepository homesRepository(HomesRepositoryRef ref) {
  return HomesRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
  );
}

@riverpod
Stream<List<HomeMembership>> userMemberships(
    UserMembershipsRef ref, String uid) {
  return ref.watch(homesRepositoryProvider).watchUserMemberships(uid);
}
