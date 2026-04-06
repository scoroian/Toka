import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'vacation.freezed.dart';

@freezed
class Vacation with _$Vacation {
  const factory Vacation({
    required String uid,
    required String homeId,
    DateTime? startDate,
    DateTime? endDate,
    @Default(false) bool isActive,
    String? reason,
    required DateTime createdAt,
  }) = _Vacation;

  const Vacation._();

  bool get isAbsent {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  factory Vacation.fromMap(String uid, String homeId, Map<String, dynamic> map) {
    return Vacation(
      uid: uid,
      homeId: homeId,
      isActive: map['isActive'] as bool? ?? false,
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
      reason: map['reason'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'isActive': isActive,
    'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
    'reason': reason,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
