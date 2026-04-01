import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toka/core/theme/app_colors.dart';

void main() {
  group('AppColors', () {
    test('primary is coral #F4845F', () {
      expect(AppColors.primary.value, equals(const Color(0xFFF4845F).value));
    });
    test('secondary is mint #81C99C', () {
      expect(AppColors.secondary.value, equals(const Color(0xFF81C99C).value));
    });
    test('surface is off-white #FAFAF8', () {
      expect(AppColors.surface.value, equals(const Color(0xFFFAFAF8).value));
    });
    test('background is light grey #F2F2EF', () {
      expect(AppColors.background.value, equals(const Color(0xFFF2F2EF).value));
    });
    test('error is soft red #E05C5C', () {
      expect(AppColors.error.value, equals(const Color(0xFFE05C5C).value));
    });
    test('textPrimary is dark grey #2D2D2D', () {
      expect(AppColors.textPrimary.value, equals(const Color(0xFF2D2D2D).value));
    });
    test('textSecondary is mid grey #7A7A7A', () {
      expect(AppColors.textSecondary.value, equals(const Color(0xFF7A7A7A).value));
    });
  });
}
