import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../homes/domain/invitation.dart';
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

@Riverpod(keepAlive: true)
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchHomeMembers(homeId);
}

@riverpod
Stream<({String code, DateTime expiresAt})?> activeInviteCode(
    ActiveInviteCodeRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchActiveInviteCode(homeId);
}

/// Lista reactiva de invitaciones pendientes (no usadas y no expiradas)
/// del hogar. Usado en el sheet de "Invitaciones pendientes" del
/// `home_settings_screen`. Read protegido a admin/owner por reglas
/// Firestore.
@riverpod
Stream<List<Invitation>> pendingInvitations(
    PendingInvitationsRef ref, String homeId) {
  return ref.watch(membersRepositoryProvider).watchPendingInvitations(homeId);
}
