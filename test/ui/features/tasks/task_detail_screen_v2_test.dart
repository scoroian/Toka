import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/task_detail_view_model.dart';
import 'package:toka/features/tasks/presentation/skins/task_detail_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockTaskDetailViewModel extends Mock implements TaskDetailViewModel {}

Widget _wrap(Widget child, TaskDetailViewModel vm) => ProviderScope(
      overrides: [
        taskDetailViewModelProvider('t1').overrideWith((_) => vm),
      ],
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
  late _MockTaskDetailViewModel vm;

  setUp(() {
    vm = _MockTaskDetailViewModel();
  });

  testWidgets('muestra loading spinner', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(const TaskDetailScreenV2(taskId: 't1'), vm));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('usa tipo abstracto TaskDetailViewModel', (tester) async {
    expect(vm, isA<TaskDetailViewModel>());
  });
}
