import 'recurrence_rule.dart';
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

    // Reglas específicas para tareas puntuales:
    //   * date debe ser parseable como "YYYY-MM-DD"
    //   * date no puede estar en el pasado más allá de 24 h
    final rule = input.recurrenceRule;
    if (rule is OneTimeRule) {
      final parsed = DateTime.tryParse(rule.date);
      if (parsed == null) {
        return ValidationResult.error(
            'recurrence', 'tasks_validation_one_time_date_invalid');
      }
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (parsed.isBefore(today.subtract(const Duration(days: 1)))) {
        return ValidationResult.error(
            'recurrence', 'tasks_validation_one_time_date_past');
      }
    }

    return ValidationResult.ok;
  }
}
