import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/constants/routes.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/shared/widgets/skins/shell_metrics.dart';

class _FakeSkinMode extends SkinMode {
  @override
  AppSkin build() => AppSkin.v2;
  @override
  Future<void> set(AppSkin skin) async => state = skin;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('returns MainShellV2Metrics when skin is v2', () {
    final c = ProviderContainer(
      overrides: [skinModeProvider.overrideWith(_FakeSkinMode.new)],
    );
    addTearDown(c.dispose);
    c.read(skinModeProvider.notifier).set(AppSkin.v2);
    final metrics = c.read(shellMetricsProvider);
    expect(metrics, isA<MainShellV2Metrics>());
    expect(metrics.navBarHeight, 56);
    expect(metrics.navBarBottom, 12);
  });

  test('returns MainShellFuturistaMetrics when skin is futurista', () {
    final c = ProviderContainer(
      overrides: [skinModeProvider.overrideWith(_FakeSkinMode.new)],
    );
    addTearDown(c.dispose);
    c.read(skinModeProvider.notifier).set(AppSkin.futurista);
    final metrics = c.read(shellMetricsProvider);
    expect(metrics, isA<MainShellFuturistaMetrics>());
    expect(metrics.navBarHeight, 64);
    expect(metrics.navBarBottom, 12);
  });

  test('suppresses banner only on /settings in both impls', () {
    const v2 = MainShellV2Metrics();
    const fut = MainShellFuturistaMetrics();
    expect(v2.suppressBannerFor(AppRoutes.settings), isTrue);
    expect(v2.suppressBannerFor(AppRoutes.home), isFalse);
    expect(fut.suppressBannerFor(AppRoutes.settings), isTrue);
    expect(fut.suppressBannerFor(AppRoutes.home), isFalse);
  });
}
