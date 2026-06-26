import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_aware_bottom_padding.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';
import 'package:toka/shared/widgets/ad_banner_notice_provider.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';
import 'package:toka/shared/widgets/skins/shell_presence_marker.dart';

final _noticeState = StateProvider<bool>((_) => false);

void main() {
  testWidgets('adAwareBottomPadding suma la caption cuando es visible',
      (t) async {
    late double captured;

    final container = ProviderContainer(overrides: [
      adBannerConfigProvider
          .overrideWith((ref) => const AdBannerConfig(show: true, unitId: '')),
      adBannerNoticeVisibleProvider
          .overrideWith((ref) => ref.watch(_noticeState)),
    ]);
    addTearDown(container.dispose);

    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: ShellPresenceMarker(
          child: Consumer(builder: (context, ref, _) {
            captured = adAwareBottomPadding(context, ref);
            return const SizedBox();
          }),
        ),
      ),
    ));

    final withoutNotice = captured;
    container.read(_noticeState.notifier).state = true;
    await t.pump();
    final withNotice = captured;

    expect(
      withNotice - withoutNotice,
      BannerPremiumNoticeCaption.kNoticeHeight + AdBanner.kBannerGap,
    );
  });
}
