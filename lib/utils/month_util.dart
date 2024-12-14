// Usage: MonthUtil.getMonthName(1) => 'January'
class MonthUtil {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  static String getMonthName(int month) {
    return _monthNames[month - 1];
  }
}
