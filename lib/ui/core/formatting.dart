import 'package:crudo/domain/shared/meal_time.dart';

// Display + route-param formatting shared across features (today, meals).

String _two(int n) => n.toString().padLeft(2, '0');

/// 'HH:mm' of a MealTime (24h).
String mealTimeLabel(MealTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// 'HH:mm' of a local instant.
String timeOfDayLabel(DateTime local) =>
    '${_two(local.hour)}:${_two(local.minute)}';

/// Route-param form of a UTC day label: '2026-06-07'.
String dayParam(DateTime dayLabel) =>
    '${dayLabel.year.toString().padLeft(4, '0')}-'
    '${_two(dayLabel.month)}-${_two(dayLabel.day)}';

/// Parses [dayParam] output back to the UTC-midnight day label.
DateTime parseDayParam(String s) {
  final p = DateTime.parse(s);
  return DateTime.utc(p.year, p.month, p.day);
}

/// Trims trailing ".0" — "3.6" stays "3.6", "31.0" renders as "31".
/// (Moved from foods/views/formatting.dart — meals feature needs it too.)
String gramsText(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

/// Normalises a user-typed number string (comma or dot decimal) and parses
/// it. Returns null when the string is not a valid number.
double? parseGrams(String s) => double.tryParse(s.replaceAll(',', '.'));
