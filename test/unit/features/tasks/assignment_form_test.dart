import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/application/create_edit_task_view_model.dart';

void main() {
  group('MemberOrderItem', () {
    test('isAssigned true para miembro en rotación', () {
      const item = MemberOrderItem(
        uid: 'u1',
        name: 'Ana',
        photoUrl: null,
        isAssigned: true,
        position: 0,
      );
      expect(item.isAssigned, isTrue);
      expect(item.position, 0);
    });

    test('isAssigned false para miembro no asignado', () {
      const item = MemberOrderItem(
        uid: 'u2',
        name: 'Bea',
        photoUrl: null,
        isAssigned: false,
        position: -1,
      );
      expect(item.isAssigned, isFalse);
    });
  });

  group('UpcomingDateItem', () {
    test('assigneeName puede ser null', () {
      final item = UpcomingDateItem(date: DateTime(2026, 4, 15));
      expect(item.assigneeName, isNull);
    });

    test('assigneeName presente cuando hay asignado', () {
      final item = UpcomingDateItem(
          date: DateTime(2026, 4, 16), assigneeName: 'Carlos');
      expect(item.assigneeName, 'Carlos');
    });
  });

  group('CreateEditTaskViewModel — lógica pura', () {
    test('canSave false cuando nombre vacío', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(name: '', assignedMemberCount: 1),
        isFalse,
      );
    });

    test('canSave false cuando no hay miembros asignados', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(name: 'Barrer', assignedMemberCount: 0),
        isFalse,
      );
    });

    test('canSave true cuando nombre y al menos 1 miembro', () {
      expect(
        CreateEditTaskViewModel.computeCanSave(name: 'Barrer', assignedMemberCount: 1),
        isTrue,
      );
    });

    test('showApplyToday false cuando hasFixedTime == false', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: false,
          fixedTime: const TimeOfDay(hour: 10, minute: 0),
          now: const TimeOfDay(hour: 9, minute: 0),
        ),
        isFalse,
      );
    });

    test('showApplyToday true cuando hora fija es posterior a ahora', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: true,
          fixedTime: const TimeOfDay(hour: 15, minute: 0),
          now: const TimeOfDay(hour: 10, minute: 0),
        ),
        isTrue,
      );
    });

    test('showApplyToday false cuando hora fija ya pasó', () {
      expect(
        CreateEditTaskViewModel.computeShowApplyToday(
          hasFixedTime: true,
          fixedTime: const TimeOfDay(hour: 8, minute: 0),
          now: const TimeOfDay(hour: 12, minute: 0),
        ),
        isFalse,
      );
    });
  });
}
