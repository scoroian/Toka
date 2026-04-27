// lib/features/settings/application/settings_view_model.dart
import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_state.dart';

part 'settings_view_model.g.dart';

class SettingsViewData {
  const SettingsViewData({
    required this.isPremium,
    required this.homeId,
    required this.uid,
    this.appVersion,
  });
  final bool isPremium;
  final String homeId;
  final String uid;
  final String? appVersion;
}

abstract class SettingsViewModel {
  SettingsViewData get viewData;
}

class _SettingsViewModelImpl implements SettingsViewModel {
  const _SettingsViewModelImpl({required this.viewData});
  @override
  final SettingsViewData viewData;
}

bool _computeIsPremium(SubscriptionState state) => state.map(
      free: (_) => false,
      active: (_) => true,
      cancelledPendingEnd: (_) => true,
      rescue: (_) => true,
      expiredFree: (_) => false,
      restorable: (_) => false,
      purged: (_) => false,
    );

@riverpod
Future<String> appVersion(AppVersionRef ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
}

@riverpod
SettingsViewModel settingsViewModel(SettingsViewModelRef ref) {
  final subState = ref.watch(subscriptionStateProvider);
  final auth = ref.watch(authProvider);
  final uid = auth.whenOrNull(authenticated: (u) => u.uid) ?? '';
  final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
  final versionAsync = ref.watch(appVersionProvider);

  return _SettingsViewModelImpl(
    viewData: SettingsViewData(
      isPremium: _computeIsPremium(subState),
      homeId: homeId,
      uid: uid,
      appVersion: versionAsync.valueOrNull,
    ),
  );
}
