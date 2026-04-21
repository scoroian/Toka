enum TaskStatus {
  active,
  frozen,
  deleted,
  /// Tarea puntual ya completada. No vuelve a aparecer en la lista Hoy ni
  /// se cuenta como tarea activa, pero se conserva para historial.
  completedOneTime;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.active,
    );
  }
}
