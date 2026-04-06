import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/members_repository_impl.dart';
import '../domain/member.dart';
import '../domain/members_repository.dart';

part 'members_provider.g.dart';

@Riverpod(keepAlive: true)
MembersRepository membersRepository(MembersRepositoryRef ref) {
  return MembersRepositoryImpl(
    firestore: FirebaseFirestore.instance,
    functions: FirebaseFunctions.instance,
  );
}

@riverpod
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchHomeMembers(homeId);
}
