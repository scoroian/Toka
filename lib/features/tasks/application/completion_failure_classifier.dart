// lib/features/tasks/application/completion_failure_classifier.dart
import 'package:cloud_functions/cloud_functions.dart';

import '../domain/failed_completion.dart';

/// Clasifica un error del callable `applyTaskCompletion` para decidir la UX del
/// fallo (Hallazgo #02):
///   - `conflict`: la tarea ya fue resuelta por otra persona o ya no está
///     activa (`permission-denied`, `failed-precondition`, `not-found`).
///     Reintentar fallaría de nuevo; se avisa y se refresca el estado real.
///   - `transient`: cualquier otro error (red, `unavailable`, `deadline-exceeded`,
///     etc.). Reintentar con la misma clave de idempotencia es seguro.
CompletionFailureKind classifyCompletionFailure(Object error) {
  if (error is FirebaseFunctionsException) {
    switch (error.code) {
      case 'permission-denied':
      case 'failed-precondition':
      case 'not-found':
        return CompletionFailureKind.conflict;
    }
  }
  return CompletionFailureKind.transient;
}
