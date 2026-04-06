import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String nickname,
    required String? photoUrl,
    required String? bio,
    required String? phone,
    required String phoneVisibility,
    required String locale,
  }) = _UserProfile;

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) =>
      UserProfile(
        uid: uid,
        nickname: data['nickname'] as String? ?? '',
        photoUrl: data['photoUrl'] as String?,
        bio: data['bio'] as String?,
        phone: data['phone'] as String?,
        phoneVisibility:
            data['phoneVisibility'] as String? ?? 'hidden',
        locale: data['locale'] as String? ?? 'es',
      );
}
