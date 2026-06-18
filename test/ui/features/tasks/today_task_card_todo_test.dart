import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';
import 'package:toka/features/tasks/domain/home_dashboard.dart';
import 'package:toka/features/tasks/presentation/widgets/today_task_card_todo.dart';
import 'package:toka/l10n/app_localizations.dart';

// TodayTaskCardTodo es ConsumerWidget: hace fallback a userProfileProvider
// cuando falta nombre/foto del asignado. Necesita un ProviderScope; se override
// con un stream vacío para no tocar Firestore (el card usa el nombre del task).
Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        for (final uid in const ['uid1', 'uid2'])
          userProfileProvider(uid)
              .overrideWith((ref) => Stream<UserProfile>.empty()),
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
          body: SingleChildScrollView(child: child),
        ),
      ),
    );

TaskPreview _makeTask({
  String uid = 'uid1',
  bool isOverdue = false,
}) =>
    TaskPreview(
      taskId: 't1',
      title: 'Barrer la cocina',
      visualKind: 'emoji',
      visualValue: '🧹',
      recurrenceType: 'daily',
      currentAssigneeUid: uid,
      currentAssigneeName: 'Ana',
      currentAssigneePhoto: null,
      nextDueAt: DateTime(2026, 4, 6, 18, 0),
      isOverdue: isOverdue,
      status: 'active',
    );

void main() {
  testWidgets('golden: card Por hacer con botones visibles', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid1'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_with_buttons.png'),
    );
  });

  testWidgets('golden: card Por hacer sin botones (otro responsable)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(uid: 'uid2'),
        currentUid: 'uid1',
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_no_buttons.png'),
    );
  });

  testWidgets('golden: card vencida', (tester) async {
    await tester.pumpWidget(
      _wrap(TodayTaskCardTodo(
        task: _makeTask(isOverdue: true),
        currentUid: null,
        now: DateTime(2026, 4, 6, 10, 0),
      )),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/today_card_todo_overdue.png'),
    );
  });
}
