// lib/features/tasks/application/create_edit_task_view_model.dart
// ignore_for_file: unused_element_parameter, library_private_types_in_public_api
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
import '../domain/recurrence_rule.dart';
import 'recurrence_provider.dart';
import 'task_form_provider.dart';
import 'tasks_provider.dart';

part 'create_edit_task_view_model.freezed.dart';
part 'create_edit_task_view_model.g.dart';

/// A member in the ordered list of task assignees.
class MemberOrderItem {
  const MemberOrderItem({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.isAssigned,
    required this.position,
  });
  final String  uid;
  final String  name;
  final String? photoUrl;
  final bool    isAssigned;
  final int     position; // 0-based; ignored if !isAssigned
}

/// An upcoming occurrence date with the assignee's name.
class UpcomingDateItem {
  const UpcomingDateItem({required this.date, this.assigneeName});
  final DateTime date;
  final String?  assigneeName;
}

@freezed
class _CreateEditVMState with _$CreateEditVMState {
  const factory _CreateEditVMState({
    @Default(false) bool savedSuccessfully,
    String? loadedTitle,
    String? loadedDescription,
    @Default(false) bool hasFixedTime,
    int? fixedTimeMinutes,   // stored as total minutes; null = no time set
    @Default(false) bool applyToday,
  }) = __CreateEditVMState;
}

abstract class CreateEditTaskViewModel {
  bool get isEditing;
  TaskFormState get formState;
  bool get savedSuccessfully;
  String? get loadedTitle;
  String? get loadedDescription;

  // New getters
  bool                   get hasFixedTime;
  TimeOfDay?             get fixedTime;
  bool                   get showApplyToday;
  bool                   get applyToday;
  List<UpcomingDateItem> get upcomingDates;
  List<MemberOrderItem>  get orderedMembers;
  bool                   get canSave;

  // Existing actions
  void setTitle(String v);
  void setDescription(String v);
  void setVisual(String kind, String value);
  void setRecurrenceRule(RecurrenceRule rule);
  void setAssignmentMode(String mode);
  void setAssignmentOrder(List<String> order);
  void setDifficultyWeight(double v);
  Future<void> save();

  // New actions
  void setHasFixedTime(bool value);
  void setFixedTime(TimeOfDay? time);
  void setApplyToday(bool value);
  void toggleMember(String uid);
  void reorderMember(int fromIndex, int toIndex);

  /// Pure logic — testable without Riverpod.
  static bool computeShowApplyToday({
    required bool hasFixedTime,
    required TimeOfDay? fixedTime,
    required TimeOfDay now,
  }) {
    if (!hasFixedTime || fixedTime == null) return false;
    final fixedMinutes = fixedTime.hour * 60 + fixedTime.minute;
    final nowMinutes   = now.hour * 60 + now.minute;
    return fixedMinutes > nowMinutes;
  }

  static bool computeCanSave({
    required String name,
    required int assignedMemberCount,
  }) =>
      name.trim().isNotEmpty && assignedMemberCount >= 1;
}

@riverpod
class CreateEditTaskViewModelNotifier
    extends _$CreateEditTaskViewModelNotifier
    implements CreateEditTaskViewModel {
  TaskFormNotifier get _form => ref.read(taskFormNotifierProvider.notifier);

  @override
  _CreateEditVMState build(String? editTaskId) {
    if (editTaskId != null) {
      Future.microtask(() => _loadForEdit(editTaskId));
    } else {
      Future.microtask(() => _form.initCreate());
    }
    return const _CreateEditVMState();
  }

  Future<void> _loadForEdit(String taskId) async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    if (homeId == null) return;
    final task =
        await ref.read(tasksRepositoryProvider).fetchTask(homeId, taskId);
    _form.initEdit(task);
    state = state.copyWith(
      loadedTitle: task.title,
      loadedDescription: task.description ?? '',
    );
  }

  @override
  bool get isEditing =>
      ref.read(taskFormNotifierProvider).mode == TaskFormMode.edit;

  @override
  TaskFormState get formState => ref.read(taskFormNotifierProvider);

  @override
  bool get savedSuccessfully => state.savedSuccessfully;

  @override
  String? get loadedTitle => state.loadedTitle;

  @override
  String? get loadedDescription => state.loadedDescription;

  @override
  bool get hasFixedTime => state.hasFixedTime;

  @override
  TimeOfDay? get fixedTime {
    final mins = state.fixedTimeMinutes;
    if (mins == null) return null;
    return TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
  }

  @override
  bool get showApplyToday => CreateEditTaskViewModel.computeShowApplyToday(
        hasFixedTime: state.hasFixedTime,
        fixedTime: fixedTime,
        now: TimeOfDay.now(),
      );

  @override
  bool get applyToday => state.applyToday;

  @override
  List<UpcomingDateItem> get upcomingDates {
    final rule = ref.read(taskFormNotifierProvider).recurrenceRule;
    if (rule == null) return [];
    final dates = ref.read(upcomingOccurrencesProvider(rule));
    final order = ref.read(taskFormNotifierProvider).assignmentOrder;
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id ?? '';
    final members =
        ref.read(homeMembersProvider(homeId)).valueOrNull ?? [];
    final nameMap = {for (final m in members) m.uid: m.nickname};

    return dates.take(3).toList().asMap().entries.map((e) {
      final assigneeUid = order.isNotEmpty ? order[e.key % order.length] : null;
      return UpcomingDateItem(
        date: e.value,
        assigneeName: assigneeUid != null ? nameMap[assigneeUid] : null,
      );
    }).toList();
  }

  @override
  List<MemberOrderItem> get orderedMembers {
    final homeId  = ref.read(currentHomeProvider).valueOrNull?.id ?? '';
    final members = ref.read(homeMembersProvider(homeId)).valueOrNull ?? [];
    final order   = ref.read(taskFormNotifierProvider).assignmentOrder;
    final assigned = Set<String>.from(order);

    final assignedItems = order.asMap().entries.map((e) {
      final uid = e.value;
      final m   = members.where((m) => m.uid == uid).firstOrNull;
      return MemberOrderItem(
        uid: uid,
        name: m?.nickname ?? uid,
        photoUrl: m?.photoUrl,
        isAssigned: true,
        position: e.key,
      );
    }).toList();

    final unassigned = members
        .where((m) => !assigned.contains(m.uid))
        .map((m) => MemberOrderItem(
              uid: m.uid,
              name: m.nickname,
              photoUrl: m.photoUrl,
              isAssigned: false,
              position: -1,
            ))
        .toList();

    return [...assignedItems, ...unassigned];
  }

  @override
  bool get canSave {
    final form = ref.read(taskFormNotifierProvider);
    return CreateEditTaskViewModel.computeCanSave(
      name: form.title,
      assignedMemberCount: form.assignmentOrder.length,
    );
  }

  @override
  void setTitle(String v) => _form.setTitle(v);

  @override
  void setDescription(String v) => _form.setDescription(v);

  @override
  void setVisual(String kind, String value) => _form.setVisual(kind, value);

  @override
  void setRecurrenceRule(RecurrenceRule rule) => _form.setRecurrenceRule(rule);

  @override
  void setAssignmentMode(String mode) => _form.setAssignmentMode(mode);

  @override
  void setAssignmentOrder(List<String> order) =>
      _form.setAssignmentOrder(order);

  @override
  void setDifficultyWeight(double v) => _form.setDifficultyWeight(v);

  @override
  void setHasFixedTime(bool value) {
    if (!value) {
      state = state.copyWith(hasFixedTime: false, fixedTimeMinutes: null);
    } else {
      state = state.copyWith(hasFixedTime: true);
    }
  }

  @override
  void setFixedTime(TimeOfDay? time) {
    state = state.copyWith(
      fixedTimeMinutes:
          time != null ? time.hour * 60 + time.minute : null,
    );
  }

  @override
  void setApplyToday(bool value) => state = state.copyWith(applyToday: value);

  @override
  void toggleMember(String uid) {
    final current =
        List<String>.from(ref.read(taskFormNotifierProvider).assignmentOrder);
    if (current.contains(uid)) {
      current.remove(uid);
    } else {
      current.add(uid);
    }
    _form.setAssignmentOrder(current);
  }

  @override
  void reorderMember(int fromIndex, int toIndex) {
    final current =
        List<String>.from(ref.read(taskFormNotifierProvider).assignmentOrder);
    if (fromIndex >= current.length || toIndex > current.length) return;
    final item = current.removeAt(fromIndex);
    current.insert(toIndex > fromIndex ? toIndex - 1 : toIndex, item);
    _form.setAssignmentOrder(current);
  }

  @override
  Future<void> save() async {
    final homeId = ref.read(currentHomeProvider).valueOrNull?.id;
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (homeId == null) return;
    final taskId = await _form.save(homeId, uid);
    if (taskId != null) {
      state = state.copyWith(savedSuccessfully: true);
    }
  }
}

@riverpod
CreateEditTaskViewModel createEditTaskViewModel(
  CreateEditTaskViewModelRef ref,
  String? editTaskId,
) {
  ref.watch(createEditTaskViewModelNotifierProvider(editTaskId));
  ref.watch(taskFormNotifierProvider);
  return ref.read(createEditTaskViewModelNotifierProvider(editTaskId).notifier);
}
