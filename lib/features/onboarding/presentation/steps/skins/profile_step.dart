import 'package:flutter/material.dart';
import 'package:toka/core/theme/skin_switcher.dart';

import 'futurista/profile_step_futurista.dart';
import 'profile_step_v2.dart';

/// Wrapper que delega en la skin activa (`v2` o `futurista`).
class ProfileStep extends StatelessWidget {
  const ProfileStep({
    super.key,
    required this.nickname,
    required this.phoneNumber,
    required this.phoneVisible,
    required this.photoLocalPath,
    required this.isLoading,
    required this.error,
    required this.onNicknameChanged,
    required this.onPhoneChanged,
    required this.onPhoneVisibleChanged,
    required this.onPhotoChanged,
    required this.onNext,
    required this.onPrev,
  });

  final String? nickname;
  final String? phoneNumber;
  final bool phoneVisible;
  final String? photoLocalPath;
  final bool isLoading;
  final String? error;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String?> onPhoneChanged;
  final ValueChanged<bool> onPhoneVisibleChanged;
  final ValueChanged<String?> onPhotoChanged;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) => ProfileStepV2(
          nickname: nickname,
          phoneNumber: phoneNumber,
          phoneVisible: phoneVisible,
          photoLocalPath: photoLocalPath,
          isLoading: isLoading,
          error: error,
          onNicknameChanged: onNicknameChanged,
          onPhoneChanged: onPhoneChanged,
          onPhoneVisibleChanged: onPhoneVisibleChanged,
          onPhotoChanged: onPhotoChanged,
          onNext: onNext,
          onPrev: onPrev,
        ),
        futurista: (_) => ProfileStepFuturista(
          nickname: nickname,
          phoneNumber: phoneNumber,
          phoneVisible: phoneVisible,
          photoLocalPath: photoLocalPath,
          isLoading: isLoading,
          error: error,
          onNicknameChanged: onNicknameChanged,
          onPhoneChanged: onPhoneChanged,
          onPhoneVisibleChanged: onPhoneVisibleChanged,
          onPhotoChanged: onPhotoChanged,
          onNext: onNext,
          onPrev: onPrev,
        ),
      );
}
