export 'package:crudo/ui/core/formatting.dart'
    show mealTimeLabel, timeOfDayLabel;

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
