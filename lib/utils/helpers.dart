import 'package:intl/intl.dart';

/// Calendar helpers. Everything works in the device's local time.
class Dates {
  Dates._();

  static DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Uses calendar arithmetic (not `Duration`) so daylight-saving changes
  /// can't shift a day boundary.
  static DateTime addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday of the week containing [d] (weeks run Monday to Sunday).
  static DateTime startOfWeek(DateTime d) =>
      addDays(startOfDay(d), -(d.weekday - 1));

  static DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);

  static DateTime nextMidnight(DateTime d) => addDays(startOfDay(d), 1);
}

/// Display formatting shared by the screens.
class Fmt {
  Fmt._();

  static final NumberFormat _int = NumberFormat.decimalPattern();
  static final DateFormat _time = DateFormat('h:mm a');
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _weekday = DateFormat('EEE');

  /// `1250` -> `1,250 ml`
  static String ml(int value) => '${_int.format(value)} ml';

  /// `1250` -> `1.3 L`, `2000` -> `2 L`
  static String liters(int ml, {int decimals = 1}) {
    final value = ml / 1000;
    final text = value.toStringAsFixed(decimals);
    return '${text.replaceFirst(RegExp(r'\.?0+$'), '')} L';
  }

  /// Glasses with at most one decimal: `500` -> `2`, `375` -> `1.5`.
  static String glasses(int ml, {int mlPerGlass = 250}) {
    final text = (ml / mlPerGlass).toStringAsFixed(1);
    return text.replaceFirst(RegExp(r'\.0$'), '');
  }

  static String time(DateTime d) => _time.format(d);

  static String date(DateTime d) => _date.format(d);

  static String weekday(DateTime d) => _weekday.format(d);

  static String percent(double fraction) =>
      '${(fraction * 100).round().clamp(0, 999)}%';

  static String greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }
}

class Validators {
  Validators._();

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Please enter your email';
    if (!_email.hasMatch(text)) return 'Please enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  /// Optional-looking but strict: 10-15 digits, optional leading `+`.
  static String? phone(String? value) {
    final text = (value ?? '').replaceAll(RegExp(r'[\s\-()]'), '');
    if (text.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(text)) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}
