// test/ui/features/plans/view_models/plan_draft_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/plans/view_models/plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

PlanSlotDraft slot(String id, int min) => (
  id: id,
  mealTemplateId: 't-$id',
  time: MealTime(min),
  mealName: id,
  kcal: 100,
);

void main() {
  group('PlanDraft — slot operations', () {
    test('addSlot keeps ascending by time', () {
      final d = const PlanDraft(
        name: 'P',
        days: [],
        active: true,
        slots: [],
      ).addSlot(slot('b', 720)).addSlot(slot('a', 480));
      check(d.slots.map((s) => s.id)).deepEquals(['a', 'b']);
    });

    test('canSave needs name + >=1 slot', () {
      const blank = PlanDraft(name: '', days: [], active: true, slots: []);
      check(blank.canSave).isFalse();

      // name non-empty but no slots → still false
      const noSlots = PlanDraft(name: 'P', days: [], active: true, slots: []);
      check(noSlots.canSave).isFalse();

      // name + slot → true
      final valid = PlanDraft(
        name: 'P',
        days: [],
        active: true,
        slots: [slot('a', 480)],
      );
      check(valid.canSave).isTrue();
    });

    test('reorderSlots redistributes sorted time-pool to positions', () {
      final d = const PlanDraft(name: 'P', days: [], active: true, slots: [])
          .addSlot(slot('a', 480))
          .addSlot(slot('b', 720))
          .addSlot(slot('c', 1080));
      // drag 'c' (index 2) to front (index 0)
      final r = d.reorderSlots(2, 0);
      check(r.slots.map((s) => s.id)).deepEquals(['c', 'a', 'b']);
      check(
        r.slots.map((s) => s.time.minutesOfDay),
      ).deepEquals([480, 720, 1080]);
    });

    test('setSlotTime re-sorts', () {
      final d = const PlanDraft(
        name: 'P',
        days: [],
        active: true,
        slots: [],
      ).addSlot(slot('a', 480)).addSlot(slot('b', 720));
      final r = d.setSlotTime(0, const MealTime(1000)); // move 'a' late
      check(r.slots.map((s) => s.id)).deepEquals(['b', 'a']);
    });

    test('removeSlot removes by index', () {
      final d = const PlanDraft(name: 'P', days: [], active: true, slots: [])
          .addSlot(slot('a', 480))
          .addSlot(slot('b', 720))
          .addSlot(slot('c', 1080));
      final r = d.removeSlot(1); // remove b
      check(r.slots.map((s) => s.id)).deepEquals(['a', 'c']);
    });
  });

  group('PlanDraft', () {
    final PlanSlotDraft pdSlot = (
      id: 's1',
      mealTemplateId: 'mt1',
      time: const MealTime(480),
      mealName: 'Breakfast',
      kcal: 500,
    );

    const plan = PlanTemplate(
      id: 'p1',
      name: 'Test Plan',
      days: [0, 2, 4],
      active: true,
      slots: [PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480))],
    );

    test('claimedDays returns days when active, empty when inactive', () {
      final draft = PlanDraft.from(plan, [pdSlot]);
      check(draft.claimedDays).deepEquals([0, 2, 4]);

      final inactiveDraft = PlanDraft(
        name: 'Test',
        days: [0, 2, 4],
        active: false,
        slots: [pdSlot],
      );
      check(inactiveDraft.claimedDays).isEmpty();
    });

    test('canSave returns false for blank names, true for valid names', () {
      final blankDraft = PlanDraft(
        name: '   ',
        days: [],
        active: true,
        slots: [pdSlot],
      );
      check(blankDraft.canSave).isFalse();

      final validDraft = PlanDraft(
        name: 'Cut',
        days: [],
        active: true,
        slots: [pdSlot],
      );
      check(validDraft.canSave).isTrue();
    });

    test(
      'toggleDay adds weekday when absent, removes when present, keeps ascending',
      () {
        final draft = PlanDraft(
          name: 'Test',
          days: [0, 4],
          active: true,
          slots: [pdSlot],
        );

        // Add wed (2) → [0, 2, 4]
        final withWed = draft.toggleDay(2);
        check(withWed.days).deepEquals([0, 2, 4]);

        // Remove wed → back to [0, 4]
        final withoutWed = withWed.toggleDay(2);
        check(withoutWed.days).deepEquals([0, 4]);
      },
    );

    test(
      'withName and withActive change only their field, slots preserved by identity',
      () {
        final draft = PlanDraft.from(plan, [pdSlot]);

        final renamed = draft.withName('X');
        check(renamed.name).equals('X');
        check(renamed.active).isTrue();
        check(renamed.days).deepEquals([0, 2, 4]);
        check(identical(renamed.slots, draft.slots)).isTrue();

        final deactivated = draft.withActive(false);
        check(deactivated.active).isFalse();
        check(deactivated.name).equals('Test Plan');
        check(deactivated.days).deepEquals([0, 2, 4]);
        check(identical(deactivated.slots, draft.slots)).isTrue();
      },
    );

    test(
      'isDirtyFrom false for identical, true after mutations, order-insensitive on days',
      () {
        final draft = PlanDraft.from(plan, [pdSlot]);

        // Unchanged → not dirty
        check(draft.isDirtyFrom(plan)).isFalse();

        // After withName → dirty
        check(draft.withName('New Name').isDirtyFrom(plan)).isTrue();

        // After toggleDay → dirty
        check(draft.toggleDay(5).isDirtyFrom(plan)).isTrue();

        // After withActive → dirty
        check(draft.withActive(false).isDirtyFrom(plan)).isTrue();

        // Order-insensitive: same days in different order → not dirty
        final planOrdered = PlanTemplate(
          id: 'p1',
          name: 'Test Plan',
          days: [2, 0, 4], // different order
          active: true,
          slots: [
            PlanSlot(id: 's1', mealTemplateId: 'mt1', time: MealTime(480)),
          ],
        );
        check(draft.isDirtyFrom(planOrdered)).isFalse();
      },
    );

    test(
      'PlanDraft.from copies days list — mutating draft days never touches source plan',
      () {
        final draft = PlanDraft.from(plan, [pdSlot]);

        // Toggle a day on the draft
        final mutated = draft.toggleDay(2);

        // Mutated draft no longer has day 2
        check(mutated.days.contains(2)).isFalse();
        // Original plan still has [0, 2, 4]
        check(plan.days).deepEquals([0, 2, 4]);
      },
    );

    test('isDirtyFrom detects slot changes', () {
      final draft = PlanDraft.from(plan, [pdSlot]);

      // Identical slots → not dirty
      check(draft.isDirtyFrom(plan)).isFalse();

      // Different slot id → dirty
      final planDifferentSlot = PlanTemplate(
        id: 'p1',
        name: 'Test Plan',
        days: [0, 2, 4],
        active: true,
        slots: [PlanSlot(id: 's2', mealTemplateId: 'mt1', time: MealTime(480))],
      );
      check(draft.isDirtyFrom(planDifferentSlot)).isTrue();
    });
  });
}
