import 'package:intl/intl.dart';

class DateFormatter {
  static String formatFull(DateTime date) {
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  static String formatShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(aDate).inDays;

    if (difference == 0) {
      return 'Today, ${formatTime(date)}';
    } else if (difference == 1) {
      return 'Yesterday, ${formatTime(date)}';
    } else if (difference == -1) {
      return 'Tomorrow, ${formatTime(date)}';
    } else if (difference < 7 && difference > 0) {
      return '${DateFormat('EEEE').format(date)}, ${formatTime(date)}';
    } else {
      return DateFormat('dd MMM, hh:mm a').format(date);
    }
  }
}
