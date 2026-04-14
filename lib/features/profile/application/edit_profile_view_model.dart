// lib/features/profile/application/edit_profile_view_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../domain/user_profile.dart';
import 'profile_provider.dart';

part 'edit_profile_view_model.freezed.dart';
part 'edit_profile_view_model.g.dart';

abstract class EditProfileViewModel {
  bool get isInitialized;
  bool get phoneVisible;
  bool get isLoading;
  bool get savedSuccessfully;
  String? get initialNickname;
  String? get initialBio;
  String? get initialPhone;
  String? get initialPhotoUrl;
  String? get selectedPhotoPath;
  void setPhoneVisible(bool v);
  void setPhoto(String? path);
  Future<void> save({
    required String nickname,
    required String bio,
    required String phone,
  });
}

@freezed
class _EditProfileVMState with _$EditProfileVMState {
  const factory _EditProfileVMState({
    @Default(false) bool isInitialized,
    @Default(false) bool phoneVisible,
    @Default(false) bool isLoading,
    @Default(false) bool savedSuccessfully,
    String? initialNickname,
    String? initialBio,
    String? initialPhone,
    String? initialPhotoUrl,
    String? selectedPhotoPath,
  }) = __EditProfileVMState;
}

@riverpod
class EditProfileViewModelNotifier extends _$EditProfileViewModelNotifier
    implements EditProfileViewModel {
  @override
  _EditProfileVMState build() {
    final uid =
        ref.watch(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    if (uid.isNotEmpty) {
      // Use ref.listen (not ref.watch) so Firestore emissions do NOT
      // re-run build() and reset isInitialized back to false.
      ref.listen<AsyncValue<UserProfile>>(
        userProfileProvider(uid),
        (_, next) {
          next.whenData((profile) {
            if (!state.isInitialized) {
              state = state.copyWith(
                isInitialized: true,
                phoneVisible: profile.phoneVisibility == 'sameHomeMembers',
                initialNickname: profile.nickname,
                initialBio: profile.bio ?? '',
                initialPhone: profile.phone ?? '',
                initialPhotoUrl: profile.photoUrl,
              );
            }
          });
        },
      );
      // Also apply if the profile is already loaded when build() runs.
      ref.read(userProfileProvider(uid)).whenData((profile) {
        Future.microtask(() {
          if (!state.isInitialized) {
            state = state.copyWith(
              isInitialized: true,
              phoneVisible: profile.phoneVisibility == 'sameHomeMembers',
              initialNickname: profile.nickname,
              initialBio: profile.bio ?? '',
              initialPhone: profile.phone ?? '',
              initialPhotoUrl: profile.photoUrl,
            );
          }
        });
      });
    }
    return const _EditProfileVMState();
  }

  @override
  bool get isInitialized => state.isInitialized;
  @override
  bool get phoneVisible => state.phoneVisible;
  @override
  bool get isLoading => state.isLoading;
  @override
  bool get savedSuccessfully => state.savedSuccessfully;
  @override
  String? get initialNickname => state.initialNickname;
  @override
  String? get initialBio => state.initialBio;
  @override
  String? get initialPhone => state.initialPhone;
  @override
  String? get initialPhotoUrl => state.initialPhotoUrl;
  @override
  String? get selectedPhotoPath => state.selectedPhotoPath;

  @override
  void setPhoneVisible(bool v) => state = state.copyWith(phoneVisible: v);

  @override
  void setPhoto(String? path) => state = state.copyWith(selectedPhotoPath: path);

  @override
  Future<void> save({
    required String nickname,
    required String bio,
    required String phone,
  }) async {
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(profileEditorProvider.notifier).updateProfile(
            uid,
            nickname: nickname,
            bio: bio,
            phone: phone,
            phoneVisibility:
                state.phoneVisible ? 'sameHomeMembers' : 'hidden',
            photoLocalPath: state.selectedPhotoPath,
          );
      // AsyncValue.guard no relanza errores, los pone en el estado del editor.
      // Verificamos explícitamente si hubo error.
      final editorState = ref.read(profileEditorProvider);
      if (editorState.hasError) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, savedSuccessfully: true);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

@riverpod
EditProfileViewModel editProfileViewModel(EditProfileViewModelRef ref) {
  ref.watch(editProfileViewModelNotifierProvider);
  return ref.read(editProfileViewModelNotifierProvider.notifier);
}
