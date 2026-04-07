import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/tasks_repository_impl.dart';
import '../domain/task.dart';
import '../domain/tasks_repository.dart';

part 'tasks_provider.g.dart';

@Riverpod(keepAlive: true)
TasksRepository tasksRepository(TasksRepositoryRef ref) {
  return TasksRepositoryImpl(firestore: FirebaseFirestore.instance);
}

@riverpod
Stream<List<Task>> homeTasks(HomeTasksRef ref, String homeId) {
  return ref.watch(tasksRepositoryProvider).watchHomeTasks(homeId);
}
