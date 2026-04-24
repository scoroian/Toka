import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/features/members/application/member_profile_view_model.dart';
import 'package:toka/features/members/presentation/skins/member_profile_screen.dart';
import 'package:toka/features/members/presentation/skins/member_profile_screen_v2.dart';
import 'package:toka/features/profile/presentation/skins/futurista/profile_screen_futurista.dart';
import 'package:toka/l10n/app_localizations.dart';

class _FakeMemberProfileViewModel implements MemberProfileViewModel {
  const _FakeMemberProfileViewModel(this.viewData);

  @override
  final AsyncValue<MemberProfileViewData?> viewData;

  @override
  Future<void> promoteToAdmin(String homeId, String uid) async {}

  @override
  Future<void> demoteFromAdmin(String homeId, String uid) async {}

  @override
  Future<void> removeMember(String homeId, String uid) async {}
}

const _testHomeId = 'home_1';
const _testUid = 'user_1';

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
        home: MemberProfileScreen(homeId: _testHomeId, memberUid: _testUid),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('wrapper renders v2 by default', (tester) async {
    final c = ProviderContainer(overrides: [
      memberProfileViewModelProvider(
              homeId: _testHomeId, memberUid: _testUid)
          .overrideWith(
        (ref) =>
            const _FakeMemberProfileViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    await tester.pump();
    expect(find.byType(MemberProfileScreenV2), findsOneWidget);
    expect(find.byType(ProfileScreenFuturista), findsNothing);
  });

  testWidgets('wrapper renders futurista when skin = futurista',
      (tester) async {
    SharedPreferences.setMockInitialValues(
        {SkinMode.persistKey: AppSkin.futurista.persistKey});
    final c = ProviderContainer(overrides: [
      memberProfileViewModelProvider(
              homeId: _testHomeId, memberUid: _testUid)
          .overrideWith(
        (ref) =>
            const _FakeMemberProfileViewModel(AsyncValue.loading()),
      ),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(_harness(container: c));
    // Pumps discretos: evitamos pumpAndSettle porque el estado loading muestra
    // un CircularProgressIndicator infinito.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.byType(ProfileScreenFuturista), findsOneWidget);
    expect(find.byType(MemberProfileScreenV2), findsNothing);
  });
}
