enum TaskStatus {
  active,
  frozen,
  deleted;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TaskStatus.active,
    );
  }
}
