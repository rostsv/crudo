import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/domain/services/plan_scheduling.dart';

PlanSlot _slot(String id, String tplId) =>
    PlanSlot(id: id, mealTemplateId: tplId, time: const MealTime(480));

void main() {
  test('no references → empty usage', () {
    final p = PlanTemplate(id: 'p', name: 'P', slots: [_slot('s1', 'other')]);
    final u = templateUsage([p], 't1');
    check(u.using).isEmpty();
    check(u.wouldEmpty).isEmpty();
  });

  test('referenced but plan keeps other slots → using, not wouldEmpty', () {
    final a = PlanTemplate(
      id: 'a',
      name: 'A',
      slots: [_slot('s1', 't1'), _slot('s2', 't2')],
    );
    final b = PlanTemplate(id: 'b', name: 'B', slots: [_slot('s3', 't3')]);
    final u = templateUsage([a, b], 't1');
    check(u.using.map((p) => p.id)).deepEquals(['a']);
    check(u.wouldEmpty).isEmpty();
  });

  test('template is plan only meal → wouldEmpty', () {
    final c = PlanTemplate(id: 'c', name: 'C', slots: [_slot('s1', 't1')]);
    final u = templateUsage([c], 't1');
    check(u.using.map((p) => p.id)).deepEquals(['c']);
    check(u.wouldEmpty.map((p) => p.id)).deepEquals(['c']);
  });

  test('duplicate refs but other slot remains → not wouldEmpty', () {
    final d = PlanTemplate(
      id: 'd',
      name: 'D',
      slots: [_slot('s1', 't1'), _slot('s2', 't1'), _slot('s3', 't5')],
    );
    final u = templateUsage([d], 't1');
    check(u.wouldEmpty).isEmpty();
    final stripped = stripTemplateFromPlan(d, 't1');
    check(stripped.slots.map((s) => s.id)).deepEquals(['s3']);
    check(stripped.name).equals('D');
  });
}
