import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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

  // El dashboard (homes/{homeId}/views/dashboard) lo reconstruye SIEMPRE el
  // trigger Firestore server-side `onTaskWriteUpdateDashboard` ante cualquier
  // alta/edición/borrado de tarea. El cliente ya NO es responsable de pedir la
  // reconstrucción: antes llamaba a la callable `refreshDashboard` con un catch
  // silencioso y, si esa llamada fallaba (sin red), la pantalla "Hoy" quedaba
  // desfasada hasta el cron de medianoche (Hallazgo #07).

  CollectionReference<Map<String, dynamic>> _col(String homeId) =>
      _db.collection('homes').doc(homeId).collection('tasks');

  @override
  Stream<List<Task>> watchHomeTasks(String homeId) {
    // Cota de seguridad (convención: nunca leer listas completas sin límite).
    // Un hogar no debería tener cientos de tareas activas; 200 cubre con holgura
    // y evita una lectura ilimitada si los datos se corrompen.
    return _col(homeId)
        .where('status', whereIn: ['active', 'frozen'])
        .orderBy('nextDueAt')
        .limit(200)
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
    // El ALTA pasa por la callable `createTask` (Hallazgo #14): el límite Free
    // se aplica server-side de forma transaccional, contando las tareas activas
    // reales en el momento. Así una ráfaga de altas no puede eludir el tope
    // leyendo un contador denormalizado. `createdByUid` lo fija el backend desde
    // la auth del request (no se envía).
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now(),
        preferToday: input.applyToday);
    final callable = _functions.httpsCallable('createTask');
    final result = await callable.call<Map<String, dynamic>>({
      'homeId': homeId,
      'task': TaskModel.toCallablePayload(input, nextDue),
    });
    return result.data['taskId'] as String;
  }

  @override
  Future<void> updateTask(
      String homeId, String taskId, TaskInput input) async {
    final nextDue = RecurrenceCalculator.nextDue(
        input.recurrenceRule, DateTime.now(),
        preferToday: input.applyToday);
    final ref = _col(homeId).doc(taskId);
    // Leemos el estado guardado (no el del formulario) para decidir si la
    // rotación cambió: si otro miembro pasó turno mientras se editaba, el
    // responsable vigente está en Firestore, no en el TaskInput. Así editar un
    // campo no-asignación nunca reinicia la rotación (Hallazgo #11b).
    final snap = await ref.get();
    final prev = snap.data();
    final previousOrder =
        List<String>.from(prev?['assignmentOrder'] as List? ?? const []);
    final currentAssigneeUid = prev?['currentAssigneeUid'] as String?;
    final data = TaskModel.toUpdateMap(
      input,
      nextDue,
      previousOrder: previousOrder,
      currentAssigneeUid: currentAssigneeUid,
    );
    await ref.update(data);
  }

  @override
  Future<void> freezeTask(String homeId, String taskId) async {
    await _col(homeId).doc(taskId).update({
      'status': 'frozen',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unfreezeTask(String homeId, String taskId) async {
    await _col(homeId).doc(taskId).update({
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteTask(
      String homeId, String taskId, String deletedByUid) async {
    // Borrado lógico: la tarea queda con status 'deleted' pero se conserva el
    // documento. `deletedAt` deja constancia del momento para auditoría y para
    // una futura limpieza/purga de tareas borradas.
    await _col(homeId).doc(taskId).update({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
