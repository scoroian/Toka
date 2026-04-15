import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/members/application/member_profile_view_model.dart';
import 'package:toka/features/members/presentation/skins/member_profile_screen_v2.dart';
import 'package:toka/l10n/app_localizations.dart';

class _MockMemberProfileViewModel extends Mock implements MemberProfileViewModel {}

Widget _wrap(Widget child, MemberProfileViewModel vm) => ProviderScope(
  overrides: [
    memberProfileViewModelProvider(homeId: 'h1', memberUid: 'u1')
        .overrideWith((_) => vm),
  ],
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
  late _MockMemberProfileViewModel vm;
  setUp(() { vm = _MockMemberProfileViewModel(); });

  testWidgets('muestra loading spinner', (tester) async {
    when(() => vm.viewData).thenReturn(const AsyncValue.loading());
    await tester.pumpWidget(_wrap(
        const MemberProfileScreenV2(homeId: 'h1', memberUid: 'u1'), vm));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('usa tipo abstracto MemberProfileViewModel', (tester) async {
    expect(vm, isA<MemberProfileViewModel>());
  });
}
