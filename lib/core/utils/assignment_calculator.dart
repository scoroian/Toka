abstract class AssignmentCalculator {
  static String? getNextAssignee(
    List<String> order,
    String currentUid,
    List<String> frozenUids,
  ) {
    if (order.isEmpty) return null;
    final eligible = order.where((uid) => !frozenUids.contains(uid)).toList();
    if (eligible.isEmpty) return currentUid;
    final currentIndex = eligible.indexOf(currentUid);
    final nextIndex = (currentIndex + 1) % eligible.length;
    return eligible[nextIndex];
  }
}
