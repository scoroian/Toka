// test/unit/features/profile/own_profile_view_model_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/own_profile_view_model.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

void main() {
  group('OwnProfileViewData', () {
    test('holds profile, hasEmailPassword, and radarEntries', () {
      final profile = UserProfile(
        uid: 'u1',
        nickname: 'Alice',
        photoUrl: null,
        bio: 'Hello',
        phone: null,
        phoneVisibility: 'hidden',
        locale: 'es',
      );

      const viewData = OwnProfileViewData(
        profile: UserProfile(
          uid: 'u1',
          nickname: 'Alice',
          photoUrl: null,
          bio: 'Hello',
          phone: null,
          phoneVisibility: 'hidden',
          locale: 'es',
        ),
        hasEmailPassword: true,
        radarEntries: AsyncValue.data([]),
      );

      expect(viewData.profile.uid, 'u1');
      expect(viewData.hasEmailPassword, isTrue);
      expect(viewData.radarEntries, isA<AsyncData>());
      // suppress unused warning
      expect(profile.uid, 'u1');
    });

    test('hasEmailPassword is false when provider list is empty', () {
      const viewData = OwnProfileViewData(
        profile: UserProfile(
          uid: 'u2',
          nickname: 'Bob',
          photoUrl: null,
          bio: null,
          phone: null,
          phoneVisibility: 'hidden',
          locale: 'en',
        ),
        hasEmailPassword: false,
        radarEntries: AsyncValue.data([]),
      );

      expect(viewData.hasEmailPassword, isFalse);
      expect(viewData.profile.nickname, 'Bob');
    });
  });
}
