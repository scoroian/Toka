import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:toka/features/homes/application/dashboard_provider.dart';

part 'ad_banner_config_provider.g.dart';

class AdBannerConfig {
  const AdBannerConfig({required this.show, required this.unitId});
  final bool show;
  final String unitId;
}

@Riverpod(keepAlive: true)
AdBannerConfig adBannerConfig(AdBannerConfigRef ref) {
  final dashboard = ref.watch(dashboardProvider).valueOrNull;
  return AdBannerConfig(
    show: dashboard?.adFlags.showBanner ?? false,
    unitId: dashboard?.adFlags.bannerUnit ?? '',
  );
}
