import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';
import 'package:toka/shared/widgets/ad_banner.dart';
import 'package:toka/shared/widgets/ad_banner_config_provider.dart';

class _MockAllTasksViewModel extends Mock implements AllTasksViewModel {}

void main() {
  testWidgets(
    'FAB queda por encima de la altura del banner cuando banner está visible',
    (t) async {
      final vm = _MockAllTasksViewModel();
      when(() => vm.isSelectionMode).thenReturn(false);
      when(() => vm.selectedIds).thenReturn({});
      when(() => vm.viewData).thenReturn(
        const AsyncValue.data(
          AllTasksViewData(
            tasks: [],
            filter: AllTasksFilter(status: TaskStatus.active),
            canManage: true,
            uid: 'u1',
            homeId: 'h1',
          ),
        ),
      );

      await t.pumpWidget(
        ProviderScope(
          overrides: [
            adBannerConfigProvider.overrideWith(
              (ref) => const AdBannerConfig(show: true, unitId: 'x'),
            ),
            allTasksViewModelProvider.overrideWith((_) => vm),
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
      // Delay corto para permitir la animación scale-in del FAB sin
      // bloquearse en pumpAndSettle (el banner puede tener timers activos).
      await t.pump(const Duration(milliseconds: 400));

      final fab = find.byKey(const Key('create_task_fab'));
      expect(
        fab,
        findsOneWidget,
        reason: 'El FAB create_task_fab debe renderizarse con canManage=true',
      );

      final fabBox = t.getRect(fab);
      final screenHeight = t.view.physicalSize.height / t.view.devicePixelRatio;
      const reservedBanner = AdBanner.kBannerHeight + AdBanner.kBannerGap;

      expect(
        fabBox.bottom,
        lessThanOrEqualTo(screenHeight - reservedBanner),
        reason: 'FAB debe estar encima de la franja reservada al banner',
      );
    },
  );
}
