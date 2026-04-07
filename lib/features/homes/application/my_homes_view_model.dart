// lib/features/homes/application/my_homes_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../domain/home_membership.dart';
import 'current_home_provider.dart';
import 'homes_provider.dart';

part 'my_homes_view_model.g.dart';

abstract class MyHomesViewModel {
  AsyncValue<List<HomeMembership>> get memberships;
  String get currentHomeId;
  void switchHome(String homeId);
}

class _MyHomesViewModelImpl implements MyHomesViewModel {
  const _MyHomesViewModelImpl({
    required this.memberships,
    required this.currentHomeId,
    required this.ref,
  });

  @override
  final AsyncValue<List<HomeMembership>> memberships;
  @override
  final String currentHomeId;
  final Ref ref;

  @override
  void switchHome(String homeId) =>
      ref.read(currentHomeProvider.notifier).switchHome(homeId);
}

@riverpod
MyHomesViewModel myHomesViewModel(MyHomesViewModelRef ref) {
  final uid = ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid);
  final membershipsAsync = uid != null
      ? ref.watch(userMembershipsProvider(uid))
      : const AsyncValue<List<HomeMembership>>.data([]);
  final currentHomeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';

  return _MyHomesViewModelImpl(
    memberships: membershipsAsync,
    currentHomeId: currentHomeId,
    ref: ref,
  );
}
