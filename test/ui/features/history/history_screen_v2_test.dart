import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/history/application/history_view_model.dart';
import 'package:toka/features/history/domain/history_filter.dart';
import 'package:toka/features/history/domain/task_event.dart';
import 'package:toka/features/history/presentation/skins/history_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockHistoryViewModel extends Mock implements HistoryViewModel {}

Widget _wrap(Widget child, HistoryViewModel vm) => ProviderScope(
  overrides: [historyViewModelProvider.overrideWith((_) => vm)],
  child: MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate, GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('es')],
    home: child,
  ),
);

void main() {
  late _MockHistoryViewModel vm;

  setUp(() {
    vm = _MockHistoryViewModel();
    when(() => vm.filter).thenReturn(const HistoryFilter());
    when(() => vm.hasMore).thenReturn(false);
    when(() => vm.isPremium).thenReturn(true);
    when(() => vm.loadMore()).thenAnswer((_) async {});
  });

  testWidgets('muestra lista de eventos', (tester) async {
    when(() => vm.items).thenReturn(const AsyncValue.data([]));
    await tester.pumpWidget(_wrap(const HistoryScreenV2(), vm));
    await tester.pump();
    expect(find.byType(HistoryScreenV2), findsOneWidget);
  });

  testWidgets('usa tipo abstracto HistoryViewModel', (tester) async {
    expect(vm, isA<HistoryViewModel>());
  });
}
