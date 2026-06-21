import 'package:freezed_annotation/freezed_annotation.dart';
import '../../homes/domain/home_membership.dart';

part 'member.freezed.dart';

@freezed
class Member with _$Member {
  const factory Member({
    required String uid,
    required String homeId,
    required String nickname,
    required String? photoUrl,
    required String? bio,
    required String? phone,
    required String phoneVisibility,
    required MemberRole role,
    required MemberStatus status,
    required DateTime joinedAt,
    required int tasksCompleted,
    required int passedCount,
    required double complianceRate,
    required int currentStreak,
    required double averageScore,
    /// True si la cuenta del usuario fue eliminada (member doc con
    /// accountDeleted=true). Se usa para NO ofrecer reincorporar una cuenta
    /// inexistente ni mostrar su uid crudo en "Antiguos miembros".
    @Default(false) bool accountDeleted,
    /// True si el miembro se marcó de vacaciones/ausente (vacation.isActive).
    /// Alimenta el indicador en la lista de miembros.
    @Default(false) bool vacationActive,
  }) = _Member;
}

extension MemberPhoneExtension on Member {
  /// Devuelve el teléfono solo si el visor tiene permiso de verlo.
  String? phoneForViewer({required bool isSelf}) {
    if (isSelf) return phone;
    if (phoneVisibility == 'sameHomeMembers') return phone;
    return null;
  }
}
