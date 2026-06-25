// lib/features/members/application/vacation_view_model.dart
//
// Falsos positivos del analyzer (ver explicación en `login_view_model.dart`).
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/vacation.dart';
import 'vacation_provider.dart';

part 'vacation_view_model.freezed.dart';
part 'vacation_view_model.g.dart';

abstract class VacationViewModel {
  bool get isInitialized;
  bool get isActive;
  DateTime? get startDate;
  DateTime? get endDate;
  String? get reason;
  bool get savedSuccessfully;
  void setActive(bool v);
  void setStartDate(DateTime d);
  void setEndDate(DateTime d);
  Future<void> save({required String? reason});
}

@freezed
class _VacationVMState with _$VacationVMState {
  const factory _VacationVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    @Default(false) bool savedSuccessfully,
  }) = __VacationVMState;
}

@riverpod
class VacationViewModelNotifier extends _$VacationViewModelNotifier
    implements VacationViewModel {
  @override
  _VacationVMState build(String homeId, String uid) {
    // Cargamos la vacación existente UNA sola vez (flag isInitialized) y luego
    // dejamos que el usuario edite libremente. Usamos `ref.listen` (no
    // watch+microtask): el callback corre FUERA del build cuando el stream
    // emite, lo que es idiomático y observable en tests. Antes, el patrón
    // `Future.microtask` dentro de build no rehidrataba de forma fiable.
    ref.listen(
      memberVacationProvider(homeId: homeId, uid: uid),
      (prev, next) {
        if (state.isInitialized) return;
        next.whenData((v) {
          state = v != null
              ? state.copyWith(
                  isInitialized: true,
                  isActive: v.isActive,
                  startDate: v.startDate,
                  endDate: v.endDate,
                  reason: v.reason,
                )
              : state.copyWith(isInitialized: true);
        });
      },
    );
    return const _VacationVMState();
  }

  @override
  bool get isInitialized => state.isInitialized;
  @override
  bool get isActive => state.isActive;
  @override
  DateTime? get startDate => state.startDate;
  @override
  DateTime? get endDate => state.endDate;
  @override
  String? get reason => state.reason;
  @override
  bool get savedSuccessfully => state.savedSuccessfully;

  @override
  void setActive(bool v) => state = state.copyWith(isActive: v);
  @override
  void setStartDate(DateTime d) => state = state.copyWith(startDate: d);
  @override
  void setEndDate(DateTime d) => state = state.copyWith(endDate: d);

  @override
  Future<void> save({required String? reason}) async {
    final vacation = Vacation(
      uid: uid,
      homeId: homeId,
      isActive: state.isActive,
      startDate: state.startDate,
      endDate: state.endDate,
      reason: reason,
      createdAt: DateTime.now(),
    );
    await ref
        .read(vacationNotifierProvider.notifier)
        .save(homeId, uid, vacation);
    state = state.copyWith(savedSuccessfully: true);
  }
}

@riverpod
VacationViewModel vacationViewModel(
    VacationViewModelRef ref, String homeId, String uid) {
  ref.watch(vacationViewModelNotifierProvider(homeId, uid));
  return ref.read(vacationViewModelNotifierProvider(homeId, uid).notifier);
}
