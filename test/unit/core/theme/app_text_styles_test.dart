import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:toka/core/theme/app_colors.dart';
import 'package:toka/core/theme/app_text_styles.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Prevent google_fonts from making network requests during tests.
    // Font assets are not bundled; we only verify the synchronously-set
    // style properties (fontSize, fontWeight, color).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTextStyles', () {
    testWidgets('displayLarge has fontSize 32 and w700', (tester) async {
      final style = AppTextStyles.displayLarge;
      expect(style.fontSize, equals(32.0));
      expect(style.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('headlineMedium has fontSize 24 and w600', (tester) async {
      final style = AppTextStyles.headlineMedium;
      expect(style.fontSize, equals(24.0));
      expect(style.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('bodyLarge has fontSize 16 and w400', (tester) async {
      final style = AppTextStyles.bodyLarge;
      expect(style.fontSize, equals(16.0));
      expect(style.fontWeight, equals(FontWeight.w400));
    });

    testWidgets('bodySmall uses textSecondary color', (tester) async {
      final style = AppTextStyles.bodySmall;
      expect(style.color, equals(AppColors.textSecondary));
    });

    testWidgets('labelLarge has w500 weight', (tester) async {
      final style = AppTextStyles.labelLarge;
      expect(style.fontWeight, equals(FontWeight.w500));
    });

    testWidgets('bodySmall has fontSize 12', (tester) async {
      final style = AppTextStyles.bodySmall;
      expect(style.fontSize, equals(12.0));
    });
  });
}
