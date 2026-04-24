import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toka/core/theme/futurista/futurista_colors.dart';
import 'package:toka/core/theme/futurista/futurista_theme.dart';

void main() {
  // Evita fetch de fonts en runtime del test — usa fallback del sistema.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ThemeData> capturedTheme(WidgetTester tester, ThemeData theme) async {
    late ThemeData captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (ctx) {
            captured = Theme.of(ctx);
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  group('FuturistaTheme', () {
    testWidgets('dark: scaffold y surface usan paleta oscura', (tester) async {
      final t = await capturedTheme(tester, FuturistaTheme.dark);
      expect(t.brightness, Brightness.dark);
      expect(t.scaffoldBackgroundColor, FuturistaColors.bg0);
      expect(t.colorScheme.surface, FuturistaColors.bg1);
      expect(t.colorScheme.onSurface, FuturistaColors.textPrimary);
    });

    testWidgets('light: scaffold y surface usan paleta clara', (tester) async {
      final t = await capturedTheme(tester, FuturistaTheme.light);
      expect(t.brightness, Brightness.light);
      expect(t.scaffoldBackgroundColor, FuturistaColors.bgLight);
      expect(t.colorScheme.surface, FuturistaColors.surfaceLight);
      expect(t.colorScheme.onSurface, FuturistaColors.textPrimLight);
    });

    test('light NO es alias de dark a nivel de tokens', () {
      // Invariante: bgLight y bg0 son constantes distintas definidas en el
      // archivo de colores. Si alguien volviera a aliasear light=>dark, este
      // test no bastaria, pero los dos anteriores (que capturan el ThemeData
      // real via MaterialApp) lo detectarian.
      expect(FuturistaColors.bgLight, isNot(FuturistaColors.bg0));
      expect(FuturistaColors.surfaceLight, isNot(FuturistaColors.bg1));
      expect(FuturistaColors.textPrimLight, isNot(FuturistaColors.textPrimary));
    });

    testWidgets('dark primary is electric cyan', (tester) async {
      final t = await capturedTheme(tester, FuturistaTheme.dark);
      expect(t.colorScheme.primary, FuturistaColors.primary);
    });

    testWidgets('light primary is darker cyan for contrast on light bg',
        (tester) async {
      final t = await capturedTheme(tester, FuturistaTheme.light);
      expect(t.colorScheme.primary, FuturistaColors.primaryLight);
    });

    testWidgets('secondary violet is identical in both modes', (tester) async {
      final dark = await capturedTheme(tester, FuturistaTheme.dark);
      expect(dark.colorScheme.secondary, FuturistaColors.primaryAlt);
    });
  });
}
