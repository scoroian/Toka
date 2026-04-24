import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/presentation/skins/futurista/task_detail_screen_futurista.dart';
import 'package:toka/features/tasks/presentation/skins/task_detail_screen.dart';
import 'package:toka/features/tasks/presentation/skins/task_detail_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeTaskDetailViewModel implements TaskDetailViewModel {
  const _FakeTaskDetailViewModel(this.viewData);

  @override
  final AsyncValue<TaskDetailViewData?> viewData;

  @override
  Future<void> deleteTask(task) async {}

  @override
  Future<void> toggleFreeze(task) async {}
}

Widget _harness({required ProviderContainer container}) =>
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        locale: Locale('es'),
        supportedLocales: [Locale('es'), Locale('en'), Locale('ro')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: TaskDetailScreen(taskId: 'test_id'),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      taskDetailViewModelProvider('test_id').overrideWith(
        (ref) => const _FakeTaskDetailViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(TaskDetailScreenV2), findsOneWidget);
    expect(find.byType(TaskDetailScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      taskDetailViewModelProvider('test_id').overrideWith(
        (ref) => const _FakeTaskDetailViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque el
    // CircularProgressIndicator (estado loading) no se asienta.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(TaskDetailScreenFuturista), findsOneWidget);
    expect(find.byType(TaskDetailScreenV2), findsNothing);
  });
}
