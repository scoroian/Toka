import 'task.dart';

abstract interface class TasksRepository {
  Stream<List<Task>> watchHomeTasks(String homeId);
  Future<Task> fetchTask(String homeId, String taskId);
  Future<String> createTask(
      String homeId, TaskInput input, String createdByUid);
  Future<void> updateTask(String homeId, String taskId, TaskInput input);
  Future<void> freezeTask(String homeId, String taskId);
  Future<void> unfreezeTask(String homeId, String taskId);
  Future<void> deleteTask(String homeId, String taskId, String deletedByUid);
  Future<void> reorderAssignees(
      String homeId, String taskId, List<String> order);
}
