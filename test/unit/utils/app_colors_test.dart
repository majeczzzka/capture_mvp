import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:capture_mvp/utils/app_colors.dart';

void main() {
  group('AppColors Tests', () {
    test('Should have correctly defined background color', () {
      expect(
          AppColors.background, equals(const Color.fromRGBO(239, 238, 231, 1)));
      expect(AppColors.background.red, equals(239));
      expect(AppColors.background.green, equals(238));
      expect(AppColors.background.blue, equals(231));
      expect(AppColors.background.opacity, equals(1.0));
    });

    test('Should have correctly defined jarGridBackground color', () {
      expect(AppColors.jarGridBackground,
          equals(const Color.fromRGBO(255, 255, 255, 1)));
      expect(AppColors.jarGridBackground, equals(Colors.white));
    });

    test('Should have correctly defined fonts color', () {
      expect(AppColors.fonts, equals(const Color.fromRGBO(168, 164, 139, 1)));
      expect(AppColors.fonts.red, equals(168));
      expect(AppColors.fonts.green, equals(164));
      expect(AppColors.fonts.blue, equals(139));
    });

    test('Should have correctly defined navBar color', () {
      expect(AppColors.navBar, equals(const Color.fromRGBO(221, 219, 205, 1)));
      expect(AppColors.navBar.red, equals(221));
      expect(AppColors.navBar.green, equals(219));
      expect(AppColors.navBar.blue, equals(205));
    });

    test('Should have correctly defined selectedFonts color', () {
      expect(AppColors.selectedFonts,
          equals(const Color.fromRGBO(138, 135, 117, 1)));
      expect(AppColors.selectedFonts.red, equals(138));
      expect(AppColors.selectedFonts.green, equals(135));
      expect(AppColors.selectedFonts.blue, equals(117));
    });
  });
}
