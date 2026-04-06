class MemberLoadData {
  const MemberLoadData({
    required this.completionsRecent,
    required this.difficultyWeight,
    required this.daysSinceLastExecution,
  });

  final int completionsRecent;
  final double difficultyWeight;
  final int daysSinceLastExecution;
}

abstract class SmartAssignmentCalculator {
  /// Selecciona el siguiente asignado basándose en carga reciente.
  /// score = completionsRecent * difficultyWeight + daysSinceLastExecution * -0.1
  /// Menor score = más prioritario.
  static String selectNextAssignee({
    required List<String> order,
    required String currentUid,
    required Map<String, MemberLoadData> loadData,
    required List<String> frozenUids,
    required List<String> absentUids,
  }) {
    final eligible = order
        .where((uid) => !frozenUids.contains(uid) && !absentUids.contains(uid))
        .toList();

    if (eligible.isEmpty) return currentUid;

    return eligible.reduce((a, b) => _score(loadData[a]) <= _score(loadData[b]) ? a : b);
  }

  static double _score(MemberLoadData? data) {
    if (data == null) return 0.0;
    return data.completionsRecent * data.difficultyWeight +
        data.daysSinceLastExecution * -0.1;
  }
}
