import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/utils/smart_assignment_calculator.dart';

void main() {
  MemberLoadData load({int completions = 0, double weight = 1.0, int days = 0}) =>
      MemberLoadData(completionsRecent: completions, difficultyWeight: weight, daysSinceLastExecution: days);

  group('SmartAssignmentCalculator.selectNextAssignee', () {
    test('selecciona al menos cargado (menos completions)', () {
      final loadData = {
        'A': load(completions: 10),
        'B': load(completions: 2),
        'C': load(completions: 7),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: [],
      );
      expect(result, 'B');
    });

    test('excluye miembros ausentes', () {
      final loadData = {
        'A': load(completions: 0),
        'B': load(completions: 0),
        'C': load(completions: 0),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: ['B'],
      );
      expect(result, isNot('B'));
    });

    test('excluye miembros congelados', () {
      final loadData = {
        'A': load(completions: 5),
        'B': load(completions: 1),
        'C': load(completions: 3),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: ['B'],
        absentUids: [],
      );
      expect(result, 'C');
    });

    test('con todos ausentes/congelados: retorna currentUid', () {
      final loadData = {'A': load(), 'B': load(), 'C': load()};
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B', 'C'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: ['B', 'C'],
        absentUids: [],
      );
      expect(result, 'A');
    });

    test('prioriza mayor daysSinceLastExecution cuando completions igual', () {
      final loadData = {
        'A': load(completions: 5, days: 1),
        'B': load(completions: 5, days: 10),
      };
      final result = SmartAssignmentCalculator.selectNextAssignee(
        order: ['A', 'B'],
        currentUid: 'A',
        loadData: loadData,
        frozenUids: [],
        absentUids: [],
      );
      expect(result, 'B');
    });
  });
}
