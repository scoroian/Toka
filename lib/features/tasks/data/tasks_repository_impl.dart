import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/recurrence_calculator.dart';
import '../domain/task.dart';
import '../domain/tasks_repository.dart';
import 'task_model.dart';

class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _db = firestore,
        _functions = functions;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final _uuid = const Uuid();

  Future<void> _refreshDashboard(String homeId) async {
    try {
      await _functions.httpsCallable('refreshDashboard').call({'homeId': homeId});
    } catch (_) {
      // El dashboard se actualizará en el próximo cron si la llamada falla
    }
  }

  CollectionReference<Map<String, dynamic>> _col(String homeId) =>
      _db.collection('homes').doc(homeId).collection('tasks');

  @override
  Stream<List<Task>> watchHomeTasks(String homeId) {
    return _col(homeId)
        .where('status', whereIn: ['active', 'frozen'])
        .orderBy('nextDueAt')
        .snapshots()
        .map((s) => s.docs.map(TaskModel.fromFirestore).toList());
  }

  @override
  Future<Task> fetchTask(String homeId, String taskId) async {
    final doc = await _col(homeId).doc(taskId).get();
    return TaskModel.fromFirestore(doc);
  }

  @override
  Future<String> createTask(
      String homeId, TaskInput input, String createdByUid) async {
    final id = _uuid.v4();
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now());
    final data = TaskModel.toFirestore(input, homeId, createdByUid, nextDue);
    await _col(homeId).doc(id).set(data);
    await _refreshDashboard(homeId);
    return id;
  }

  @override
  Future<void> updateTask(
      String homeId, String taskId, TaskInput input) async {
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now());
    final data = TaskModel.toUpdateMap(input, nextDue);
    await _col(homeId).doc(taskId).update(data);
    await _refreshDashboard(homeId);
  }

  @override
  Future<void> freezeTask(String homeId, String taskId) async {
    await _col(homeId).doc(taskId).update({
      'status': 'frozen',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _refreshDashboard(homeId);
  }

  @override
  Future<void> unfreezeTask(String homeId, String taskId) async {
    await _col(homeId).doc(taskId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _refreshDashboard(homeId);
  }

  @override
  Future<void> deleteTask(
      String homeId, String taskId, String deletedByUid) async {
    await _col(homeId).doc(taskId).update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _refreshDashboard(homeId);
  }

  @override
  Future<void> reorderAssignees(
          String homeId, String taskId, List<String> order) =>
      _col(homeId).doc(taskId).update({
        'assignmentOrder': order,
        'currentAssigneeUid': order.isNotEmpty ? order.first : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
