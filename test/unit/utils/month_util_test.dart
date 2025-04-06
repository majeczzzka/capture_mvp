import 'package:flutter_test/flutter_test.dart';
import 'package:capture_mvp/utils/month_util.dart';

void main() {
  group('MonthUtil Tests', () {
    test('Should return correct month names for valid inputs', () {
      // Test all months
      expect(MonthUtil.getMonthName(1), equals('January'));
      expect(MonthUtil.getMonthName(2), equals('February'));
      expect(MonthUtil.getMonthName(3), equals('March'));
      expect(MonthUtil.getMonthName(4), equals('April'));
      expect(MonthUtil.getMonthName(5), equals('May'));
      expect(MonthUtil.getMonthName(6), equals('June'));
      expect(MonthUtil.getMonthName(7), equals('July'));
      expect(MonthUtil.getMonthName(8), equals('August'));
      expect(MonthUtil.getMonthName(9), equals('September'));
      expect(MonthUtil.getMonthName(10), equals('October'));
      expect(MonthUtil.getMonthName(11), equals('November'));
      expect(MonthUtil.getMonthName(12), equals('December'));
    });

    test('Should throw RangeError for invalid month numbers', () {
      // Test invalid months
      expect(() => MonthUtil.getMonthName(0), throwsRangeError);
      expect(() => MonthUtil.getMonthName(13), throwsRangeError);
      expect(() => MonthUtil.getMonthName(-1), throwsRangeError);
    });

    test('Should work with DateTime.month property', () {
      // Test with DateTime objects
      final januaryDate = DateTime(2023, 1, 15);
      final juneDate = DateTime(2023, 6, 30);
      final decemberDate = DateTime(2023, 12, 25);

      expect(MonthUtil.getMonthName(januaryDate.month), equals('January'));
      expect(MonthUtil.getMonthName(juneDate.month), equals('June'));
      expect(MonthUtil.getMonthName(decemberDate.month), equals('December'));
    });
  });
}
