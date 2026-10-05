import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _shortDate = DateFormat('dd MMM yyyy');
  static final DateFormat _dayDate = DateFormat('EEE, dd MMM');

  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatShortDate(DateTime date) => _shortDate.format(date);
  static String formatDayDate(DateTime date) => _dayDate.format(date);

  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  static String getBengaliMonthName(int month) {
    const bnMonths = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    if (month >= 1 && month <= 12) return bnMonths[month - 1];
    return '';
  }
}
