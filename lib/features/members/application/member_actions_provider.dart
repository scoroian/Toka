import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'members_provider.dart';

part 'member_actions_provider.g.dart';

@riverpod
class MemberActions extends _$MemberActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

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
    // NO usar AsyncValue.guard: igual que transferOwnership, guard captura la
    // excepción y NO la relanza, por lo que la UI (admins_sheet) nunca veía el
    // tope de admins (MaxAdminsReachedException) ni el bloqueo free y mostraba
    // un falso "éxito". Guardamos el error en el estado y lo relanzamos.
    state = const AsyncValue.loading();
    try {
      await ref.read(membersRepositoryProvider).promoteToAdmin(homeId, uid);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> demoteFromAdmin(String homeId, String uid) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref.read(membersRepositoryProvider).demoteFromAdmin(homeId, uid));
  }

  Future<void> transferOwnership(String homeId, String newOwnerUid) async {
    // OJO: NO usar AsyncValue.guard aquí. guard captura la excepción y la
    // guarda en `state` SIN relanzarla, por lo que el try/catch de la UI
    // (transfer_ownership_sheet) nunca veía el payer-lock y mostraba un falso
    // "éxito". Replicamos el patrón de generateInviteCode: guardamos el error
    // en el estado y lo relanzamos para que la pantalla pueda reaccionar.
    state = const AsyncValue.loading();
    try {
      await ref
          .read(membersRepositoryProvider)
          .transferOwnership(homeId, newOwnerUid);
      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> revokeInvitation(String homeId, String invitationId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ref
            .read(membersRepositoryProvider)
            .revokeInvitation(homeId, invitationId));
  }
}
