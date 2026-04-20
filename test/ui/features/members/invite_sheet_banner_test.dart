import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/members/presentation/widgets/invite_member_sheet.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

void main() {
  testWidgets(
    'InviteMemberSheet renderiza botones accesibles con banner activo',
    (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es')],
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (_) =>
                          const InviteMemberSheet(homeId: 'home-x'),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await t.tap(find.text('open'));
      await t.pumpAndSettle();

      expect(find.byKey(const Key('btn_share_code')), findsOneWidget);
      expect(find.byKey(const Key('btn_invite_email')), findsOneWidget);
    },
  );
}
