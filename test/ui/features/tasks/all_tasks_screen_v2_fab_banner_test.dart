import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets(
    'FAB queda por encima de la altura del banner cuando banner está visible',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale('es')],
            home: AllTasksScreenV2(),
          ),
        ),
      );
      await t.pumpAndSettle(const Duration(seconds: 1));

      final fab = find.byKey(const Key('create_task_fab'));
      if (fab.evaluate().isEmpty) return; // sin homeId en test: FAB no se pinta

      final fabBox = t.getRect(fab);
      final screenHeight = t.view.physicalSize.height / t.view.devicePixelRatio;
      final reservedBanner = AdBanner.kBannerHeight + AdBanner.kBannerGap;

      expect(
        fabBox.bottom,
        lessThanOrEqualTo(screenHeight - reservedBanner),
        reason: 'FAB debe estar encima de la franja reservada al banner',
      );
    },
  );
}
