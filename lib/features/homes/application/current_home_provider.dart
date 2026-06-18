import 'dart:async';

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

    // Escucha en vivo el documento `homes/{targetId}` (igual que el dashboard).
    // La PRIMERA emisión resuelve el Future de `build` (estado inicial); las
    // siguientes empujan el nuevo Home a `state`, de modo que avatar, nombre,
    // estado premium, banners y membresía propia refrescan SIN reiniciar la app.
    // Antes esto era un `repo.fetchHome(targetId)` (lectura única) y los cambios
    // del documento no llegaban a la UI hasta reiniciar (BUG-05).
    final completer = Completer<Home?>();
    final sub = repo.watchHome(targetId).listen(
      (home) {
        if (completer.isCompleted) {
          state = AsyncData(home);
        } else {
          completer.complete(home);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          state = AsyncError(error, stackTrace);
        } else {
          completer.completeError(error, stackTrace);
        }
      },
    );
    ref.onDispose(sub.cancel);

    return completer.future;
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
