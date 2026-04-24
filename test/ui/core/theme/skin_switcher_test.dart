import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/app_skin.dart';
import 'package:toka/core/theme/skin_provider.dart';
import 'package:toka/core/theme/skin_switcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget harness({required Key v2Key, required Key futuristaKey}) {
    return ProviderScope(
      child: MaterialApp(
        home: SkinSwitch(
          v2: (_) => Container(key: v2Key),
          futurista: (_) => Container(key: futuristaKey),
        ),
      ),
    );
  }

  testWidgets('renders v2 builder by default', (tester) async {
    const v2 = Key('v2');
    const fut = Key('fut');
    await tester.pumpWidget(harness(v2Key: v2, futuristaKey: fut));
    await tester.pumpAndSettle();

    expect(find.byKey(v2), findsOneWidget);
    expect(find.byKey(fut), findsNothing);
  });

  testWidgets('renders futurista builder after set(futurista)', (tester) async {
    const v2 = Key('v2');
    const fut = Key('fut');
    await tester.pumpWidget(harness(v2Key: v2, futuristaKey: fut));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SkinSwitch)),
    );
    await container.read(skinModeProvider.notifier).set(AppSkin.futurista);
    await tester.pumpAndSettle();

    expect(find.byKey(fut), findsOneWidget);
    expect(find.byKey(v2), findsNothing);
  });

  testWidgets('KeyedSubtree forces remount when skin changes', (tester) async {
    int v2Builds = 0;
    int futBuilds = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SkinSwitch(
            v2: (_) {
              v2Builds++;
              return const SizedBox();
            },
            futurista: (_) {
              futBuilds++;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(v2Builds, 1);
    expect(futBuilds, 0);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SkinSwitch)),
    );
    await container.read(skinModeProvider.notifier).set(AppSkin.futurista);
    await tester.pumpAndSettle();

    expect(futBuilds, greaterThanOrEqualTo(1));
  });
}
