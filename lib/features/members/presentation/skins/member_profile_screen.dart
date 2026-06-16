// lib/features/members/presentation/skins/member_profile_screen.dart
//
// Wrapper "skin-aware" que renderiza `MemberProfileScreenV2` (única skin
// activa) según el `SkinMode` persistido, consumiendo
// `memberProfileViewModelProvider(homeId, memberUid)`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import 'member_profile_screen_v2.dart';

class MemberProfileScreen extends StatelessWidget {
  const MemberProfileScreen({
    super.key,
    required this.homeId,
    required this.memberUid,
  });

  final String homeId;
  final String memberUid;

  @override
  Widget build(BuildContext context) => SkinSwitch(
        v2: (_) =>
            MemberProfileScreenV2(homeId: homeId, memberUid: memberUid),
      );
}
