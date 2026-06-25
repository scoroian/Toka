// Tests del clasificador de fallos del commit diferido (Hallazgo #02).
//
// Un fallo del callable `applyTaskCompletion` puede ser de dos naturalezas:
//   - conflict: la tarea ya fue resuelta por otra persona (carrera de turno) o
//     ya no está activa → reintentar NO sirve.
//   - transient: red caída / servicio no disponible → reintentar SÍ sirve.
// La clasificación se hace sobre el `code` de FirebaseFunctionsException.
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/completion_failure_classifier.dart';
import 'package:toka/features/tasks/domain/failed_completion.dart';

void main() {
  CompletionFailureKind classify(String code) => classifyCompletionFailure(
        FirebaseFunctionsException(message: code, code: code),
      );

  test('permission-denied → conflict (no es tu turno / no eres miembro)', () {
    expect(classify('permission-denied'), CompletionFailureKind.conflict);
  });

  test('failed-precondition → conflict (tarea ya no activa)', () {
    expect(classify('failed-precondition'), CompletionFailureKind.conflict);
  });

  test('not-found → conflict (la tarea ya no existe)', () {
    expect(classify('not-found'), CompletionFailureKind.conflict);
  });

  test('unavailable → transient (servicio caído, reintentable)', () {
    expect(classify('unavailable'), CompletionFailureKind.transient);
  });

  test('deadline-exceeded → transient', () {
    expect(classify('deadline-exceeded'), CompletionFailureKind.transient);
  });

  test('error que NO es FirebaseFunctionsException → transient', () {
    expect(
      classifyCompletionFailure(Exception('socket closed')),
      CompletionFailureKind.transient,
    );
  });
}
