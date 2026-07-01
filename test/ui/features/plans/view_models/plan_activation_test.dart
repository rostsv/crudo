import 'package:checks/checks.dart';
import 'package:crudo/config/di.dart';
import 'package:crudo/data/repositories/in_memory_plan_template_repository.dart';
import 'package:crudo/domain/plan/plan_template.dart';
import 'package:crudo/ui/features/plans/view_models/plan_activation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlanTemplate active; // Mon, Wed
  late PlanTemplate paused; // Wed (paused) — clashes with `active` on resume
  late PlanTemplate free; // Sat/Sun (paused) — safe to resume

  setUp(() {
    active = const PlanTemplate(
      id: 'A',
      name: 'Active',
      days: [0, 2],
      active: true,
    );
    paused = const PlanTemplate(
      id: 'P',
      name: 'Paused',
      days: [2],
      active: false,
    );
    free = const PlanTemplate(
      id: 'F',
      name: 'Free',
      days: [5, 6],
      active: false,
    );
  });

  ProviderContainer containerWith(List<PlanTemplate> plans) {
    final c = ProviderContainer(
      overrides: [
        planTemplateRepositoryProvider.overrideWithValue(
          InMemoryPlanTemplateRepository(seed: plans),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('PlanActivation', () {
    test('pause flips active to false', () async {
      final c = containerWith([active]);
      await c.read(planActivationProvider.notifier).pause('A');
      final repo = c.read(planTemplateRepositoryProvider);
      check((await repo.getById('A'))!.active).isFalse();
    });

    test('resume with no clash flips active to true', () async {
      final c = containerWith([active, free]);
      final ctrl = c.read(planActivationProvider.notifier);
      check((await ctrl.resumeConflicts('F')).isEmpty).isTrue();
      await ctrl.resume('F');
      final repo = c.read(planTemplateRepositoryProvider);
      check((await repo.getById('F'))!.active).isTrue();
    });

    test('resumeConflicts reports the clashing active plan', () async {
      final c = containerWith([active, paused]);
      final conflicts = await c
          .read(planActivationProvider.notifier)
          .resumeConflicts('P');
      final int count = conflicts.length;
      final int weekday = conflicts.first.weekday;
      check(count).equals(1);
      check(conflicts.first.otherPlanId).equals('A');
      check(weekday).equals(2);
    });

    test('resume with override resumes and strips the clashing day', () async {
      final c = containerWith([active, paused]);
      await c.read(planActivationProvider.notifier).resume('P', override: true);
      final repo = c.read(planTemplateRepositoryProvider);
      check((await repo.getById('P'))!.active).isTrue();
      // A loses Wed (2), keeps Mon (0).
      final aDays = (await repo.getById('A'))!.days;
      final int len = aDays.length;
      final int firstDay = aDays.first;
      check(len).equals(1);
      check(firstDay).equals(0);
    });
  });

  group('PlanActivation — coverage guard', () {
    // Two active plans that together cover the whole week.
    final weekdays = const PlanTemplate(
      id: 'WD',
      name: 'Weekdays',
      days: [0, 1, 2, 3, 4],
      active: true,
    );
    final weekend = const PlanTemplate(
      id: 'WE',
      name: 'Weekend',
      days: [5, 6],
      active: true,
    );

    test('daysOrphanedByPausing reports a plan\'s unique days', () async {
      final c = containerWith([weekdays, weekend]);
      final orphaned = await c
          .read(planActivationProvider.notifier)
          .daysOrphanedByPausing('WE');
      check(orphaned).deepEquals([5, 6]);
    });

    test(
      'no orphaned days when another active plan already covers them',
      () async {
        final full = const PlanTemplate(
          id: 'F',
          name: 'Full',
          days: [0, 1, 2, 3, 4, 5, 6],
          active: true,
        );
        final c = containerWith([full, weekend]);
        final orphaned = await c
            .read(planActivationProvider.notifier)
            .daysOrphanedByPausing('WE');
        check(orphaned.isEmpty).isTrue();
      },
    );

    test('otherActivePlans excludes self and paused plans', () async {
      final c = containerWith([weekdays, weekend, free]);
      final others = await c
          .read(planActivationProvider.notifier)
          .otherActivePlans('WD');
      check(others.map((p) => p.id).toList()).deepEquals(['WE']);
    });

    test('assignDaysAndPause folds days into the target and pauses', () async {
      final c = containerWith([weekdays, weekend]);
      await c
          .read(planActivationProvider.notifier)
          .assignDaysAndPause('WE', toPlanId: 'WD', days: [5, 6]);
      final repo = c.read(planTemplateRepositoryProvider);
      check((await repo.getById('WD'))!.days).deepEquals([0, 1, 2, 3, 4, 5, 6]);
      check((await repo.getById('WE'))!.active).isFalse();
    });

    test(
      'assignDaysAndDelete folds days into the target and deletes',
      () async {
        final c = containerWith([weekdays, weekend]);
        await c
            .read(planActivationProvider.notifier)
            .assignDaysAndDelete('WE', toPlanId: 'WD', days: [5, 6]);
        final repo = c.read(planTemplateRepositoryProvider);
        check(
          (await repo.getById('WD'))!.days,
        ).deepEquals([0, 1, 2, 3, 4, 5, 6]);
        check(await repo.getById('WE')).isNull();
      },
    );

    test('forceDelete removes the plan unconditionally', () async {
      final c = containerWith([weekdays, weekend]);
      await c.read(planActivationProvider.notifier).forceDelete('WD');
      check(
        await c.read(planTemplateRepositoryProvider).getById('WD'),
      ).isNull();
    });
  });
}
