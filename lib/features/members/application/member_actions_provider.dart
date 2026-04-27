import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'members_provider.dart';

part 'member_actions_provider.g.dart';

@riverpod
class MemberActions extends _$MemberActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> inviteMember(String homeId, String? email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).inviteMember(homeId, email));
  }

  Future<({String code, DateTime expiresAt})> generateInviteCode(
      String homeId) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref
          .read(membersRepositoryProvider)
          .generateInviteCode(homeId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> removeMember(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).removeMember(homeId, uid));
  }

  Future<void> promoteToAdmin(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).promoteToAdmin(homeId, uid));
  }

  Future<void> demoteFromAdmin(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).demoteFromAdmin(homeId, uid));
  }

  Future<void> transferOwnership(String homeId, String newOwnerUid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref
            .read(membersRepositoryProvider)
            .transferOwnership(homeId, newOwnerUid));
  }

  Future<void> revokeInvitation(String homeId, String invitationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref
            .read(membersRepositoryProvider)
            .revokeInvitation(homeId, invitationId));
  }
}
