import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../domain/home.dart';
import 'homes_provider.dart';

part 'current_home_provider.g.dart';

@Riverpod(keepAlive: true)
class CurrentHome extends _$CurrentHome {
  @override
  Future<Home?> build() async {
    final auth = ref.watch(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid);
    if (uid == null) return null;

    final memberships = await ref.watch(
      userMembershipsProvider(uid).future,
    );
    if (memberships.isEmpty) return null;

    final repo = ref.watch(homesRepositoryProvider);
    final lastId = await repo.getLastSelectedHomeId(uid);

    final targetId =
        (lastId != null && memberships.any((m) => m.homeId == lastId))
            ? lastId
            : memberships.first.homeId;

    return repo.fetchHome(targetId);
  }

  Future<void> switchHome(String homeId) async {
    final auth = ref.read(authProvider);
    final uid = auth.whenOrNull(authenticated: (u) => u.uid);
    if (uid == null) return;
    await ref
        .read(homesRepositoryProvider)
        .updateLastSelectedHome(uid, homeId);
    ref.invalidateSelf();
  }
}
