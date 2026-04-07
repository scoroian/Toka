import 'task.dart';

sealed class ValidationResult {
  const ValidationResult();
  static const ValidationResult ok = _Ok();
  static ValidationResult error(String field, String code) =>
      _Error(field, code);

  bool get isOk => this is _Ok;
  ({String field, String code})? get failure =>
      this is _Error
          ? (field: (this as _Error).field, code: (this as _Error).code)
          : null;
}

final class _Ok extends ValidationResult {
  const _Ok();
}

final class _Error extends ValidationResult {
  final String field;
  final String code;
  const _Error(this.field, this.code);
}

class TaskValidator {
  static ValidationResult validate(TaskInput input) {
    if (input.title.trim().isEmpty) {
      return ValidationResult.error('title', 'tasks_validation_title_empty');
    }
    if (input.title.trim().length > 60) {
      return ValidationResult.error('title', 'tasks_validation_title_too_long');
    }
    if (input.assignmentOrder.isEmpty) {
      return ValidationResult.error(
          'assignees', 'tasks_validation_no_assignees');
    }
    if (input.difficultyWeight < 0.5 || input.difficultyWeight > 3.0) {
      return ValidationResult.error(
          'difficulty', 'tasks_validation_difficulty_range');
    }
    return ValidationResult.ok;
  }
}
