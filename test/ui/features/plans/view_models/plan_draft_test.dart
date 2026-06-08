// test/ui/features/plans/view_models/plan_draft_test.dart
import 'package:checks/checks.dart';
import 'package:crudo/domain/plan/plan_slot.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/domain/shared/meal_time.dart';
import 'package:crudo/ui/features/plans/view_models/plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanDraft', () {
    final slotVm = (
      mealName: 'Breakfast',
      time: const MealTime(480),
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
      final draft = PlanDraft.from(plan, [slotVm]);
      check(draft.claimedDays).deepEquals([0, 2, 4]);

      final inactiveDraft = PlanDraft(
        name: 'Test',
        days: [0, 2, 4],
        active: false,
        slots: [slotVm],
      );
      check(inactiveDraft.claimedDays).isEmpty();
    });

    test('canSave returns false for blank names, true for valid names', () {
      final blankDraft = PlanDraft(
        name: '   ',
        days: [],
        active: true,
        slots: [slotVm],
      );
      check(blankDraft.canSave).isFalse();

      final validDraft = PlanDraft(
        name: 'Cut',
        days: [],
        active: true,
        slots: [slotVm],
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
          slots: [slotVm],
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
        final draft = PlanDraft.from(plan, [slotVm]);

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
        final draft = PlanDraft.from(plan, [slotVm]);

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
        final draft = PlanDraft.from(plan, [slotVm]);

        // Toggle a day on the draft
        final mutated = draft.toggleDay(2);

        // Mutated draft no longer has day 2
        check(mutated.days.contains(2)).isFalse();
        // Original plan still has [0, 2, 4]
        check(plan.days).deepEquals([0, 2, 4]);
      },
    );
  });
}
