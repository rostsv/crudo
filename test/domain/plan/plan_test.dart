// test/domain/plan/plan_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const slot = PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480));

  test('slot binds meal template to a time', () {
    check(slot.time.hour).equals(8);
    check(slot).equals(
      const PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480)),
    );
  });

  test('plan defaults: unassigned, active, no slots', () {
    const p = PlanTemplate(id: 'p1', name: 'Cut');
    check(p.days).isEmpty();
    check(p.active).isTrue();
    check(p.slots).isEmpty();
  });

  test('plan holds ordered slots + weekdays', () {
    const p = PlanTemplate(
      id: 'p2',
      name: 'Weekday cut',
      days: [0, 1, 2, 3, 4],
      slots: [slot],
    );
    check(p.days).deepEquals([0, 1, 2, 3, 4]);
    check(p.slots.single.mealTemplateId).equals('mt1');
    check(p.copyWith(active: false).active).isFalse();
  });
}
