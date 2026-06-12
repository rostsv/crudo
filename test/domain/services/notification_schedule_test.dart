import 'package:checks/checks.dart';
import 'package:crudo/domain/day/day.dart';
import 'package:crudo/domain/day/scheduled_meal.dart';
import 'package:crudo/domain/meal/food_snapshot.dart';
import 'package:crudo/domain/meal/meal_item.dart';
import 'package:crudo/domain/meal/meal_snapshot.dart';
import 'package:crudo/domain/profile/prefs.dart';
import 'package:crudo/domain/services/notification_schedule.dart';
import 'package:crudo/domain/services/notification_spec.dart';
import 'package:crudo/domain/shared/enums.dart';
import 'package:crudo/domain/shared/grams.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: a FoodSnapshot with a given [kcal]; other macros set to 0.
FoodSnapshot _snap({required double kcal}) => FoodSnapshot(
  name: 'food',
  kind: FoodKind.product,
  category: FoodCategory.custom,
  grams: const Grams(100),
  protein: 0,
  carbs: 0,
  fats: 0,
  kcal: kcal,
);

/// Helper: a MealItem wrapper for [kcal].
MealItem _item({required double kcal, bool checked = false}) => MealItem(
  checkedAt: checked ? DateTime.utc(2026, 6, 11, 10) : null,
  food: _snap(kcal: kcal),
);

/// Helper: a ScheduledMeal with one unchecked item of [kcal].
ScheduledMeal _meal({
  required String id,
  required int timeMinutes,
  required String name,
  double kcal = 500,
  bool checked = false,
}) => ScheduledMeal(
  id: id,
  time: MealTime(timeMinutes),
  meal: MealSnapshot(
    name: name,
    items: [_item(kcal: kcal, checked: checked)],
  ),
);

/// A typical 3-meal test day: breakfast 400, lunch 700, dinner 1000 kcal total.
/// Total planned = 2100 kcal. 80% target = 1680.
Day _threeMealDay() {
  final breakfast = _meal(
    id: 'breakfast',
    timeMinutes: 8 * 60, // 08:00
    name: 'Breakfast',
    kcal: 400,
  );
  final lunch = _meal(
    id: 'lunch',
    timeMinutes: 13 * 60, // 13:00
    name: 'Lunch',
    kcal: 700,
  );
  final dinner = _meal(
    id: 'dinner',
    timeMinutes: 19 * 60, // 19:00
    name: 'Dinner',
    kcal: 1000,
  );
  return Day(
    date: DateTime.utc(2026, 6, 11),
    meals: [breakfast, lunch, dinner],
  );
}

void main() {
  // Base date label for the day under test.
  // `now` helpers construct local-wall-clock instants on this date.
  final dayDate = DateTime.utc(2026, 6, 11);
  DateTime nowAt(int hour, [int minute = 0]) =>
      DateTime(2026, 6, 11, hour, minute);

  group('notificationSchedule', () {
    test('all toggles off → empty list', () {
      final prefs = Prefs(
        preOn: false,
        atOn: false,
        eodOn: false,
        riskOn: false,
      );
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(10));
      check(specs).isEmpty();
    });

    test('preOn only — one spec per upcoming meal, none for past', () {
      final prefs = Prefs(
        preOn: true,
        atOn: false,
        eodOn: false,
        riskOn: false,
        preMin: 30,
      );
      // At 10:00, breakfast (08:00) is past, lunch (13:00) and dinner (19:00)
      // are upcoming → 2 pre specs.
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(10));
      check(specs).length.equals(2);
      for (final s in specs) {
        check(s.kind).equals(NotificationKind.pre);
        check(s.mealId).isNotNull();
        check(s.fireAt.isUtc).isTrue();
        check(s.withActions).isFalse();
        check(s.title).equals('Coming up');
        check(s.body).contains('in 30 min');
      }
      check(specs.any((s) => s.body.contains('Lunch'))).isTrue();
      check(specs.any((s) => s.body.contains('Dinner'))).isTrue();
    });

    test('preOn — no upcoming meals (all past) → empty', () {
      final prefs = Prefs(
        preOn: true,
        atOn: false,
        eodOn: false,
        riskOn: false,
      );
      // At 22:00, all three meals are past.
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(22));
      check(specs).isEmpty();
    });

    test('atOn — specs carry withActions and fire at meal time', () {
      final prefs = Prefs(
        preOn: false,
        atOn: true,
        eodOn: false,
        riskOn: false,
      );
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(10));
      check(specs).length.equals(2);
      for (final s in specs) {
        check(s.kind).equals(NotificationKind.at);
        check(s.mealId).isNotNull();
        check(s.fireAt.isUtc).isTrue();
        check(s.withActions).isTrue();
        check(s.title).equals('Time to eat');
      }
      check(specs.any((s) => s.body.contains('Lunch'))).isTrue();
      check(specs.any((s) => s.body.contains('Dinner'))).isTrue();
    });

    test('eodOn — one endOfDay spec at 21:30 local', () {
      final prefs = Prefs(
        preOn: false,
        atOn: false,
        eodOn: true,
        riskOn: false,
      );
      // Default day (no items checked) → consumed = 0, planned = 2100.
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(10));
      check(specs).length.equals(1);
      final spec = specs.single;
      check(spec.kind).equals(NotificationKind.endOfDay);
      check(spec.mealId).isNull();
      check(spec.withActions).isFalse();
      check(spec.title).equals('Daily recap');
      check(spec.body).contains('0 of 2100 kcal');
      check(spec.fireAt.isUtc).isTrue();
    });

    test('eodOn — now after 21:30 → no eod spec', () {
      final prefs = Prefs(
        preOn: false,
        atOn: false,
        eodOn: true,
        riskOn: false,
      );
      final specs = notificationSchedule(_threeMealDay(), prefs, nowAt(22));
      check(specs).isEmpty();
    });
  });

  group('streakRiskInfo', () {
    test('planned <= 0 → null', () {
      final emptyDay = Day(date: dayDate);
      final info = streakRiskInfo(emptyDay, 80, nowAt(10));
      check(info).isNull();
    });

    test('consumed >= target → null (safe)', () {
      // All meals checked → consumed == planned == 2100.
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'Breakfast',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(
        id: 'l',
        timeMinutes: 13 * 60,
        name: 'Lunch',
        kcal: 700,
        checked: true,
      );
      final dinner = _meal(
        id: 'd',
        timeMinutes: 19 * 60,
        name: 'Dinner',
        kcal: 1000,
        checked: true,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch, dinner]);
      // 2100 >= 1680 (80% of 2100) → null
      final info = streakRiskInfo(day, 80, nowAt(10));
      check(info).isNull();
    });

    test('consumed + remaining < target → null (unrecoverable)', () {
      // Nothing checked. At 14:00, breakfast (08:00) and lunch (13:00) are past,
      // only dinner (19:00, 1000 kcal) is upcoming.
      // consumed=0, remaining=1000, target=1680 → 1000 < 1680 → null
      final info = streakRiskInfo(_threeMealDay(), 80, nowAt(14));
      check(info).isNull();
    });

    test('recoverable mid-day → returns correct pivotal meal info', () {
      // Breakfast checked (400 consumed), lunch and dinner upcoming.
      // At 10:00: breakfast done, lunch and dinner upcoming.
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'Breakfast',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(
        id: 'l',
        timeMinutes: 13 * 60,
        name: 'Lunch',
        kcal: 700,
      );
      final dinner = _meal(
        id: 'd',
        timeMinutes: 19 * 60,
        name: 'Dinner',
        kcal: 1000,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch, dinner]);

      // target = 2100 * 0.8 = 1680
      // consumed = 400, remaining = 700+1000 = 1700 → 400+1700=2100 >= 1680
      // Walking: acc=400; +lunch=1100<1680; +dinner=2100>=1680 → pivotal = dinner
      // mealsLeft = 2 (lunch, dinner)
      final info = streakRiskInfo(day, 80, nowAt(10));
      check(info).isNotNull();
      check(info!.pivotalMealId).equals('d');
      check(info.pivotalMealName).equals('Dinner');
      check(info.pivotalMealTime).equals(const MealTime(19 * 60));
      check(info.mealsLeft).equals(2);
      check(info.deadline.isUtc).isTrue();
    });

    test('recoverable with last meal as pivotal', () {
      // Breakfast checked (400 consumed), lunch upcoming.
      // No dinner meal — just 2 meals.
      // At 10:00: breakfast done, lunch upcoming.
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'Breakfast',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(
        id: 'l',
        timeMinutes: 13 * 60,
        name: 'Lunch',
        kcal: 500,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch]);

      // target = 900 * 0.8 = 720
      // consumed = 400, remaining = 500 → 400+500=900 >= 720 → recoverable
      // Walking: acc=400; +lunch(500)=900>=720 → pivotal = lunch
      // mealsLeft = 1
      final info = streakRiskInfo(day, 80, nowAt(10));
      check(info).isNotNull();
      check(info!.pivotalMealId).equals('l');
      check(info.pivotalMealName).equals('Lunch');
      check(info.mealsLeft).equals(1);
    });

    test('threshold 100% edge', () {
      // When threshold = 100, target = planned.
      // Breakfast checked (400), lunch and dinner upcoming.
      // consumed=400, remaining=1700 (not enough), target=2100
      // 400+1700=2100 >= 2100 → recoverable exactly
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'B',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(id: 'l', timeMinutes: 13 * 60, name: 'L', kcal: 700);
      final dinner = _meal(
        id: 'd',
        timeMinutes: 19 * 60,
        name: 'D',
        kcal: 1000,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch, dinner]);
      final info = streakRiskInfo(day, 100, nowAt(10));
      check(info).isNotNull();
      check(info!.pivotalMealId).equals('d');
    });
  });

  group('notificationSchedule — risk specs', () {
    test('riskOn with recoverable day → one risk spec', () {
      // Breakfast checked, lunch and dinner upcoming. Recoverable.
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'Breakfast',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(
        id: 'l',
        timeMinutes: 13 * 60,
        name: 'Lunch',
        kcal: 700,
      );
      final dinner = _meal(
        id: 'd',
        timeMinutes: 19 * 60,
        name: 'Dinner',
        kcal: 1000,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch, dinner]);

      final prefs = Prefs(
        preOn: false,
        atOn: false,
        eodOn: false,
        riskOn: true,
        streakThreshold: 80,
      );
      final specs = notificationSchedule(day, prefs, nowAt(10));
      check(specs).length.equals(1);
      final spec = specs.single;
      check(spec.kind).equals(NotificationKind.risk);
      check(spec.mealId).isNull();
      check(spec.withActions).isFalse();
      check(spec.title).equals('Streak at risk');
      check(spec.body).contains('2 meals left');
      check(spec.body).contains('Dinner');
      check(spec.fireAt.isUtc).isTrue();
    });

    test('riskOn but safe day → no risk spec', () {
      // unrecoverable day (consumed + remaining < target) → null
      final info = streakRiskInfo(_threeMealDay(), 80, nowAt(14));
      check(info).isNull();
    });

    test('pre + at + eod + risk combined', () {
      // Breakfast checked, lunch and dinner upcoming.
      final breakfast = _meal(
        id: 'b',
        timeMinutes: 8 * 60,
        name: 'Breakfast',
        kcal: 400,
        checked: true,
      );
      final lunch = _meal(
        id: 'l',
        timeMinutes: 13 * 60,
        name: 'Lunch',
        kcal: 700,
      );
      final dinner = _meal(
        id: 'd',
        timeMinutes: 19 * 60,
        name: 'Dinner',
        kcal: 1000,
      );
      final day = Day(date: dayDate, meals: [breakfast, lunch, dinner]);

      // All toggles on (default Prefs).
      final prefs = Prefs();
      final specs = notificationSchedule(day, prefs, nowAt(10));
      // Expected: 2 pre (lunch, dinner) + 2 at (lunch, dinner) + 1 eod + 1 risk = 6
      check(specs).length.equals(6);
      check(
        specs.where((s) => s.kind == NotificationKind.pre),
      ).length.equals(2);
      check(specs.where((s) => s.kind == NotificationKind.at)).length.equals(2);
      check(
        specs.where((s) => s.kind == NotificationKind.endOfDay),
      ).length.equals(1);
      check(
        specs.where((s) => s.kind == NotificationKind.risk),
      ).length.equals(1);
    });
  });
}
