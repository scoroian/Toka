import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/vacation.dart';
import 'members_provider.dart';

part 'vacation_provider.g.dart';

@riverpod
Stream<Vacation?> memberVacation(
  MemberVacationRef ref, {
  required String homeId,
  required String uid,
}) {
  return ref.watch(membersRepositoryProvider).watchVacation(homeId, uid);
}

@riverpod
class VacationNotifier extends _$VacationNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save(String homeId, String uid, Vacation vacation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(membersRepositoryProvider).saveVacation(homeId, uid, vacation);
    });
  }
}
