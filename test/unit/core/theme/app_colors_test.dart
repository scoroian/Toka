import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is coral #F4845F', () {
      expect(AppColors.primary, equals(const Color(0xFFF4845F)));
    });
    test('secondary is mint #81C99C', () {
      expect(AppColors.secondary, equals(const Color(0xFF81C99C)));
    });
    test('surface is off-white #FAFAF8', () {
      expect(AppColors.surface, equals(const Color(0xFFFAFAF8)));
    });
    test('background is light grey #F2F2EF', () {
      expect(AppColors.background, equals(const Color(0xFFF2F2EF)));
    });
    test('error is soft red #E05C5C', () {
      expect(AppColors.error, equals(const Color(0xFFE05C5C)));
    });
    test('textPrimary is dark grey #2D2D2D', () {
      expect(AppColors.textPrimary, equals(const Color(0xFF2D2D2D)));
    });
    test('textSecondary is mid grey #7A7A7A', () {
      expect(AppColors.textSecondary, equals(const Color(0xFF7A7A7A)));
    });
  });
}
