/// Time of day as minutes from midnight (0–1439). Pure value object — the UI
/// formats it; S05 maps it onto concrete schedule instants.
class MealTime implements Comparable<MealTime> {
  const MealTime(this.minutesOfDay)
    : assert(
        minutesOfDay >= 0 && minutesOfDay <= 1439,
        'minutesOfDay must be within 0..1439',
      );

  final int minutesOfDay;

  int get hour => minutesOfDay ~/ 60;
  int get minute => minutesOfDay % 60;

  @override
  int compareTo(MealTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is MealTime && other.minutesOfDay == minutesOfDay;

  @override
  int get hashCode => minutesOfDay.hashCode;

  @override
  String toString() =>
      'MealTime(${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')})';
}
