import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toka/core/theme/skin_switcher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget harness({required Key v2Key}) {
    return ProviderScope(
      child: MaterialApp(
        home: SkinSwitch(
          v2: (_) => Container(key: v2Key),
        ),
      ),
    );
  }

  testWidgets('renders v2 builder (única skin activa)', (tester) async {
    const v2 = Key('v2');
    await tester.pumpWidget(harness(v2Key: v2));
    await tester.pumpAndSettle();

    expect(find.byKey(v2), findsOneWidget);
  });

  testWidgets('el builder v2 se invoca una sola vez', (tester) async {
    int v2Builds = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SkinSwitch(
            v2: (_) {
              v2Builds++;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(v2Builds, 1);
  });
}
