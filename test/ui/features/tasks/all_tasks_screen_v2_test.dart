import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/all_tasks_view_model.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
import 'package:toka/features/tasks/presentation/skins/all_tasks_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockAllTasksViewModel extends Mock implements AllTasksViewModel {}

Widget _wrap(Widget child, AllTasksViewModel vm) => ProviderScope(
      overrides: [allTasksViewModelProvider.overrideWith((_) => vm)],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es')],
        home: child,
      ),
    );

void main() {
  late _MockAllTasksViewModel vm;

  setUp(() {
    vm = _MockAllTasksViewModel();
    when(() => vm.isSelectionMode).thenReturn(false);
    when(() => vm.selectedIds).thenReturn({});
  });

  testWidgets('muestra loading mientras carga', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(const AllTasksScreenV2(), vm));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra FAB scale-in cuando canManage=true y no hay selección',
      (tester) async {
    when(() => vm.viewData).thenReturn(AsyncValue.data(AllTasksViewData(
      tasks: [],
      filter: const AllTasksFilter(status: TaskStatus.active),
      canManage: true,
      uid: 'u1',
      homeId: 'h1',
    )));
    await tester.pumpWidget(_wrap(const AllTasksScreenV2(), vm));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('create_task_fab')), findsOneWidget);
  });

  testWidgets('usa tipo abstracto AllTasksViewModel', (tester) async {
    expect(vm, isA<AllTasksViewModel>());
  });
}
