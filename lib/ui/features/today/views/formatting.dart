import 'package:crudo/domain/shared/meal_time.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
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
  'December',
];

String _two(int n) => n.toString().padLeft(2, '0');

String mealTimeLabel(MealTime t) => '${_two(t.hour)}:${_two(t.minute)}';

String timeOfDayLabel(DateTime local) =>
    '${_two(local.hour)}:${_two(local.minute)}';

/// 'Thursday, June 4' — [dayLabel] is a UTC day-label (S02 convention).
String dateHeadline(DateTime dayLabel) =>
    '${_weekdays[dayLabel.weekday - 1]}, ${_months[dayLabel.month - 1]} ${dayLabel.day}';

String greetingFor(DateTime now, String? name) {
  final part = now.hour < 12
      ? 'morning'
      : now.hour < 18
      ? 'afternoon'
      : 'evening';
  return (name == null || name.isEmpty) ? 'Good $part' : 'Good $part, $name';
}

/// Mon..Sun UTC day-labels of the week containing [dayLabel].
List<DateTime> weekOf(DateTime dayLabel) {
  final monday = dayLabel.subtract(Duration(days: dayLabel.weekday - 1));
  return [for (var i = 0; i < 7; i++) monday.add(Duration(days: i))];
}
