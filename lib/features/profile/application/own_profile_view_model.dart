// lib/features/profile/application/own_profile_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../domain/user_profile.dart';
import '../presentation/widgets/radar_chart_widget.dart';
import 'member_radar_provider.dart';
import 'profile_provider.dart';

part 'own_profile_view_model.g.dart';

class OwnProfileViewData {
  const OwnProfileViewData({
    required this.profile,
    required this.hasEmailPassword,
    required this.radarEntries,
  });
  final UserProfile profile;
  final bool hasEmailPassword;
  final AsyncValue<List<RadarEntry>> radarEntries;
}

abstract class OwnProfileViewModel {
  AsyncValue<OwnProfileViewData?> get viewData;
  Future<void> signOut();
}

class _OwnProfileViewModelImpl implements OwnProfileViewModel {
  const _OwnProfileViewModelImpl({
    required this.viewData,
    required this.ref,
  });
  @override
  final AsyncValue<OwnProfileViewData?> viewData;
  final Ref ref;

  @override
  Future<void> signOut() => ref.read(authProvider.notifier).signOut();
}

@riverpod
OwnProfileViewModel ownProfileViewModel(OwnProfileViewModelRef ref) {
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final hasEmailPassword =
      auth.whenOrNull(authenticated: (u) => u.providers.contains('password')) ??
          false;

  if (uid.isEmpty) {
    return _OwnProfileViewModelImpl(
      viewData: const AsyncValue.data(null),
      ref: ref,
    );
  }

  final profileAsync = ref.watch(userProfileProvider(uid));
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final radarAsync = homeId.isNotEmpty
      ? ref.watch(memberRadarProvider(homeId: homeId, uid: uid))
      : const AsyncValue<List<RadarEntry>>.data([]);

  final viewData = profileAsync.whenData(
    (profile) => OwnProfileViewData(
      profile: profile,
      hasEmailPassword: hasEmailPassword,
      radarEntries: radarAsync,
    ),
  );

  return _OwnProfileViewModelImpl(viewData: viewData, ref: ref);
}
