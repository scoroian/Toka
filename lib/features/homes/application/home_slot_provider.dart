import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import 'homes_provider.dart';

part 'home_slot_provider.g.dart';

@riverpod
Future<int> availableSlots(AvailableSlotsRef ref) async {
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid);
  if (uid == null) return 0;
  return ref.read(homesRepositoryProvider).getAvailableSlots(uid);
}
