import '../../../core/errors/exceptions.dart';

export '../../../core/errors/exceptions.dart'
    show
        InvalidInviteCodeException,
        ExpiredInviteCodeException,
        NoHomeSlotsException;

abstract class HomeCreationRepository {
  /// Calls the `createHome` Cloud Function.
  /// Returns the newly created homeId.
  /// Throws [NoHomeSlotsException] if the user has no slots.
  Future<String> createHome({required String name, String? emoji});

  /// Validates the invite code and, if valid, creates the membership.
  /// Returns the homeId.
  /// Throws [InvalidInviteCodeException] or [ExpiredInviteCodeException].
  Future<String> joinHome({required String code});
}
