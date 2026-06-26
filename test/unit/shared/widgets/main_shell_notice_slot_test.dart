import 'package:flutter_test/flutter_test.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/banner_premium_notice_caption.dart';
import 'package:toka/shared/widgets/skins/main_shell_v2.dart';

void main() {
  test('noticeSlotHeight: 0 si no visible', () {
    expect(MainShellV2.noticeSlotHeight(noticeVisible: false), 0);
  });

  test('noticeSlotHeight: alto de la caption + gap si visible', () {
    expect(
      MainShellV2.noticeSlotHeight(noticeVisible: true),
      BannerPremiumNoticeCaption.kNoticeHeight + AdBanner.kBannerGap,
    );
  });
}
