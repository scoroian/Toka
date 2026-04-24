// lib/features/members/presentation/skins/member_profile_screen.dart
//
// Wrapper que elige entre `MemberProfileScreenV2` y `ProfileScreenFuturista`
// según el `SkinMode` persistido. Ambas variantes consumen
// `memberProfileViewModelProvider(homeId, memberUid)`.
import 'package:flutter/material.dart';

import '../../../../core/theme/skin_switcher.dart';
import '../../../profile/presentation/skins/futurista/profile_screen_futurista.dart';
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
        futurista: (_) => ProfileScreenFuturista(
          isOwnProfile: false,
          homeId: homeId,
          uid: memberUid,
        ),
      );
}
