// lib/features/tasks/domain/failed_completion.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failed_completion.freezed.dart';

/// Naturaleza de un fallo al confirmar la completación diferida (Hallazgo #02).
enum CompletionFailureKind {
  /// Reintentable: la escritura no llegó a aplicarse (red caída, servicio no
  /// disponible, timeout). Reintentar con la misma `completionId` es seguro e
  /// idempotente.
  transient,

  /// La tarea ya fue resuelta por otra persona (carrera de turno) o dejó de
  /// estar activa. Reintentar NO sirve: el estado real ya cambió.
  conflict,
}

/// Una completación cuyo commit al backend falló tras la ventana de Deshacer.
/// La tarea vuelve a ser visible en "Por hacer" con una marca de "no se guardó"
/// (no en silencio). `completionId` es la clave de idempotencia: se reutiliza al
/// reintentar para no duplicar el evento si la primera escritura sí llegó a
/// aplicarse pero se perdió la respuesta.
@freezed
class FailedCompletion with _$FailedCompletion {
  const factory FailedCompletion({
    required String homeId,
    required String taskId,
    required String taskTitle,
    required String completionId,
    required CompletionFailureKind kind,
  }) = _FailedCompletion;
}
